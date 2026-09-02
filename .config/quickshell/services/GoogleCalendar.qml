pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Google Calendar + Tasks, fed by scripts/gcal.py. The script owns every
// network call and writes ~/.config/quickshell/google/data.json; this singleton
// watches that file, exposes the parsed state, and shells back to the script
// for sync / login / logout and event+task mutations.
//
//   qs ipc call gcal sync
//   qs ipc call gcal login
// (the calendar popout itself: qs ipc call popout open calendar)
Singleton {
    id: root

    readonly property string script: Quickshell.shellPath("scripts/gcal.py")

    // --- parsed state ----------------------------------------------------
    property var events: []
    property var tasks: []
    property var taskLists: []
    property var calendars: []
    property var accounts: []          // [{ email, error }]
    property string syncedAt: ""

    readonly property bool connected: accounts.length > 0
    readonly property bool needsReauth:
        accounts.some(a => a.error === "reauth")
    readonly property var accountErrors:
        accounts.filter(a => a.error).map(a => a.email + ": " + a.error)

    property bool syncing: syncProc.running
    property bool loggingIn: loginProc.running
    property bool busy: actionProc.running
    property string lastError: ""

    // Optimistic task-completion: key -> target status, until the next sync
    // confirms it. Mirrors Notifications._deleting.
    property var _pending: ({})
    function pendingStatus(key) { return _pending[key]; }
    function _markPending(key, status) {
        const p = Object.assign({}, _pending);
        p[key] = status;
        _pending = p;
    }

    // --- visible / filtered views --------------------------------------
    readonly property var visibleEvents:
        events.filter(e => !GoogleConfig.isCalendarHidden(e.calendarKey))

    readonly property var writableCalendars:
        calendars.filter(c => c.accessRole === "owner" || c.accessRole === "writer")

    function _parseDay(s, allDay) {
        if (!s) return null;
        if (allDay || /^\d{4}-\d{2}-\d{2}$/.test(s)) {
            const p = s.split("-");
            return new Date(+p[0], +p[1] - 1, +p[2]);
        }
        return new Date(s);
    }

    // Events overlapping the local calendar day `d` (a JS Date), all-day first
    // then by start time.
    function eventsOn(d) {
        const dayStart = new Date(d.getFullYear(), d.getMonth(), d.getDate());
        const dayEnd = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1);
        return visibleEvents.filter(e => {
            const s = _parseDay(e.start, e.allDay);
            let en = _parseDay(e.end, e.allDay);
            if (!s) return false;
            if (!en || en <= s) en = new Date(s.getTime() + 3600000);
            return s < dayEnd && en > dayStart;
        }).sort((a, b) => {
            if (a.allDay !== b.allDay) return a.allDay ? -1 : 1;
            return _parseDay(a.start, a.allDay) - _parseDay(b.start, b.allDay);
        });
    }

    // { dayOfMonth: eventCount } for the grid dots.
    function eventDaysInMonth(year, month) {
        const first = new Date(year, month, 1);
        const next = new Date(year, month + 1, 1);
        const out = ({});
        for (const e of visibleEvents) {
            let s = _parseDay(e.start, e.allDay);
            let en = _parseDay(e.end, e.allDay);
            if (!s) continue;
            if (!en || en <= s) en = new Date(s.getTime() + 3600000);
            // all-day end is exclusive
            if (e.allDay) en = new Date(en.getTime() - 1);
            let cur = new Date(Math.max(s.getTime(), first.getTime()));
            cur = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate());
            while (cur < next && cur <= en) {
                out[cur.getDate()] = (out[cur.getDate()] || 0) + 1;
                cur = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() + 1);
            }
        }
        return out;
    }

    function tasksFor(listKey) {
        const showDone = GoogleConfig.showCompletedTasks;
        return tasks.filter(t => {
            if (listKey && t.taskListKey !== listKey) return false;
            const st = _pending[t.key] ?? t.status;
            return showDone || st !== "completed";
        }).sort((a, b) => (a.position || "").localeCompare(b.position || ""));
    }

    readonly property string effectiveTaskListKey: {
        const want = GoogleConfig.defaultTaskListKey;
        if (want && taskLists.some(l => l.key === want)) return want;
        return taskLists.length > 0 ? taskLists[0].key : "";
    }

    function _list(key) { return taskLists.find(l => l.key === key); }
    function _cal(key) { return calendars.find(c => c.key === key); }

    // --- actions -------------------------------------------------------
    function _run(proc, args) {
        root.lastError = "";
        proc.exec(["python3", root.script].concat(args));
    }

    function syncNow() {
        if (syncProc.running) return;
        _run(syncProc, ["sync",
                        "--days-back", String(GoogleConfig.daysBack),
                        "--days-fwd", String(GoogleConfig.daysForward)]);
    }
    function login()        { if (!loginProc.running) _run(loginProc, ["login"]); }
    function logout(email)  { _run(actionProc, ["logout", email]); }

    // event: { title, allDay, start, end, allDayDate, allDayEnd, location, desc }
    function addEvent(calKey, ev) {
        const c = _cal(calKey);
        if (!c) return;
        _run(actionProc, ["event-add", c.accountEmail, c.id].concat(_evArgs(ev)));
    }
    function editEvent(ev, patch) {
        _run(actionProc, ["event-edit", ev.accountEmail, ev.calendarId, ev.id]
             .concat(_evArgs(patch)));
    }
    function deleteEvent(ev) {
        _run(actionProc, ["event-delete", ev.accountEmail, ev.calendarId, ev.id]);
    }
    function _evArgs(ev) {
        const a = [];
        if (ev.title !== undefined)    a.push("--title", ev.title);
        if (ev.location !== undefined) a.push("--location", ev.location);
        if (ev.desc !== undefined)     a.push("--desc", ev.desc);
        if (ev.allDay) {
            a.push("--all-day", ev.allDayDate);
            if (ev.allDayEnd) a.push("--all-day-end", ev.allDayEnd);
        } else {
            if (ev.start) a.push("--start", ev.start);
            if (ev.end)   a.push("--end", ev.end);
        }
        return a;
    }

    function addTask(listKey, title, due) {
        const l = _list(listKey) || _list(effectiveTaskListKey);
        if (!l || !title) return;
        const a = ["task-add", l.accountEmail, l.id, "--title", title];
        if (due) a.push("--due", due);
        _run(actionProc, a);
    }
    function toggleTask(t) {
        const target = (_pending[t.key] ?? t.status) === "completed"
            ? "needsAction" : "completed";
        _markPending(t.key, target);
        _run(actionProc, ["task-toggle", t.accountEmail, t.taskListId, t.id, target]);
    }
    function editTask(t, patch) {
        const a = ["task-edit", t.accountEmail, t.taskListId, t.id];
        if (patch.title !== undefined) a.push("--title", patch.title);
        if (patch.notes !== undefined) a.push("--notes", patch.notes);
        if (patch.clearDue) a.push("--clear-due");
        else if (patch.due) a.push("--due", patch.due);
        _run(actionProc, a);
    }
    function deleteTask(t) {
        _run(actionProc, ["task-delete", t.accountEmail, t.taskListId, t.id]);
    }

    function writeClient(clientId, clientSecret) {
        clientProc.exec({
            "environment": { "CID": clientId, "CSEC": clientSecret,
                             "DIR": Quickshell.env("HOME") + "/.config/quickshell/google" },
            "command": ["bash", "-c",
                'mkdir -p "$DIR" && chmod 700 "$DIR" && ' +
                'printf \'{"client_id":"%s","client_secret":"%s"}\\n\' "$CID" "$CSEC" ' +
                '> "$DIR/client.json" && chmod 600 "$DIR/client.json"']
        });
    }
    property bool hasClient: false
    Process {
        id: clientCheck
        command: ["test", "-s", Quickshell.env("HOME") + "/.config/quickshell/google/client.json"]
        onExited: code => root.hasClient = (code === 0)
    }
    Process { id: clientProc; onExited: { clientCheck.running = true; } }

    // --- processes ----------------------------------------------------
    Process {
        id: syncProc
        stdout: StdioCollector { onStreamFinished: root._absorbResult(text) }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) console.log("[gcal]", text.trim()) }
        onExited: dataFile.reload()
    }
    Process {
        id: loginProc
        stdout: StdioCollector { onStreamFinished: root._absorbResult(text) }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) console.log("[gcal]", text.trim()) }
        onExited: code => { if (code === 0) root.syncNow(); }
    }
    Process {
        id: actionProc
        stdout: StdioCollector { onStreamFinished: root._absorbResult(text) }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) console.log("[gcal]", text.trim()) }
        onExited: code => { root.syncNow(); }
    }

    function _absorbResult(text) {
        const s = (text || "").trim();
        if (!s) return;
        try {
            const j = JSON.parse(s);
            if (j && j.error) root.lastError = j.error;
        } catch (e) { /* non-JSON diagnostic line */ }
    }

    // --- data.json --------------------------------------------------
    FileView {
        id: dataFile
        path: Quickshell.env("HOME") + "/.config/quickshell/google/data.json"
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.events = []; root.tasks = []; root.taskLists = [];
                root.calendars = []; root.accounts = [];
            }
        }
        onLoaded: {
            try {
                const j = JSON.parse(dataFile.text());
                root.events = j.events ?? [];
                root.tasks = j.tasks ?? [];
                root.taskLists = j.taskLists ?? [];
                root.calendars = j.calendars ?? [];
                root.accounts = j.accounts ?? [];
                root.syncedAt = j.syncedAt ?? "";
                root._pending = ({});   // a fresh sync is the source of truth
            } catch (e) {
                console.warn("[gcal] bad data.json", e);
            }
        }
    }

    Timer {
        interval: Math.max(5, GoogleConfig.syncIntervalMin) * 60000
        running: root.connected
        repeat: true
        onTriggered: root.syncNow()
    }
    Timer {
        id: startupSync
        interval: 3000
        running: true
        onTriggered: root.syncNow()
    }

    Component.onCompleted: {
        dataFile.reload();
        clientCheck.running = true;
    }

    IpcHandler {
        target: "gcal"
        function sync(): void { root.syncNow(); }
        function login(): void { root.login(); }
        function status(): string {
            return JSON.stringify({
                connected: root.connected, syncedAt: root.syncedAt,
                events: root.events.length, tasks: root.tasks.length,
                errors: root.accountErrors
            });
        }
    }
}
