pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Google Calendar / Tasks integration settings — sync cadence, which calendars
// are shown, where the calendar-card quick-add drops tasks. Persisted as JSON
// at ~/.config/quickshell/google.json (edited in Settings › Calendar).
//
// The accounts themselves and the synced data live under
// ~/.config/quickshell/google/ (written by scripts/gcal.py, read by
// services/GoogleCalendar.qml) — NOT here.
Singleton {
    id: root

    readonly property int syncIntervalMin: adapter.syncIntervalMin
    readonly property int daysBack: adapter.daysBack
    readonly property int daysForward: adapter.daysForward
    readonly property var hiddenCalendars: adapter.hiddenCalendars
    readonly property string defaultTaskListKey: adapter.defaultTaskListKey
    readonly property bool showCompletedTasks: adapter.showCompletedTasks
    readonly property bool weekStartsMonday: adapter.weekStartsMonday

    function setSyncInterval(min)   { adapter.syncIntervalMin = Math.max(5, Math.min(240, Math.round(min))); }
    function setDaysBack(d)         { adapter.daysBack = Math.max(0, Math.round(d)); }
    function setDaysForward(d)      { adapter.daysForward = Math.max(1, Math.round(d)); }
    function setDefaultTaskList(k)  { adapter.defaultTaskListKey = k ?? ""; }
    function setShowCompleted(v)    { adapter.showCompletedTasks = !!v; }
    function setWeekStartsMonday(v) { adapter.weekStartsMonday = !!v; }

    // --- calendar visibility (deep-clone → mutate → reassign; a `var` only
    //     notifies on reassignment — same idiom as BarConfig) ----------------
    function isCalendarHidden(key) {
        return (adapter.hiddenCalendars ?? []).indexOf(key) !== -1;
    }
    function toggleCalendar(key) {
        const cur = JSON.parse(JSON.stringify(adapter.hiddenCalendars ?? []));
        const i = cur.indexOf(key);
        if (i === -1) cur.push(key);
        else cur.splice(i, 1);
        adapter.hiddenCalendars = cur;
    }
    function setCalendarHidden(key, hidden) {
        if (isCalendarHidden(key) !== !!hidden)
            toggleCalendar(key);
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/google.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: adapter
            property int syncIntervalMin: 15
            property int daysBack: 7
            property int daysForward: 60
            property var hiddenCalendars: []
            property string defaultTaskListKey: ""
            property bool showCompletedTasks: false
            property bool weekStartsMonday: false
        }
    }
}
