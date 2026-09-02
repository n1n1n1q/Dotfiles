pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Named snapshots of the entire shell configuration — colour scheme, fonts,
// wallpaper, avatar, bar layout and desktop widgets — in one file each:
//
//   ~/.config/quickshell/presets/<name>.json
//
// Plain JSON, hand-editable and shareable, exactly like the colour schemes
// next door. Written and applied from Settings > Presets, or from a keybind:
//
//   qs ipc call preset apply minimal
//
// Every config singleton owns its own slice through `snapshot()` /
// `applySnapshot()`; a preset is just those slices stitched together under the
// keys in `parts`. Teaching presets about a new config file is a one-line
// change there.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/quickshell/presets"

    // The config singletons a preset is assembled from. The key is the one the
    // slice lands under in the JSON file.
    readonly property var parts: ({
        "appearance": Appearance,
        "bar": BarConfig,
        "desktop": DesktopConfig,
        "dashboard": DashboardConfig,
        "osd": OsdConfig,
        "launcher": LauncherConfig,
        "lock": LockConfig
    })

    // name -> preset body, as last read off disk.
    property var presets: ({})
    readonly property var names: Object.keys(presets).sort()
    readonly property int count: names.length

    // Emitted when a preset is applied from a keybind / IPC rather than picked
    // in Settings — the OSD listens for this and flashes the name, the same way
    // it does for a stepped wallpaper or scheme.
    signal presetApplied(string name)

    // --- capture / apply ----------------------------------------------------
    // The live configuration, in the shape a preset file holds.
    function capture() {
        const out = {};
        for (const key in parts)
            out[key] = parts[key].snapshot();
        return out;
    }

    // Push a body back into the config singletons. Each one writes its own
    // JSON file on assignment, so this is all it takes to retheme the shell.
    function restore(body) {
        if (!body) return;
        for (const key in parts)
            if (body[key]) parts[key].applySnapshot(body[key]);
    }

    // --- "which preset am I on?" -------------------------------------------
    // Rather than persisting a pointer that goes stale the moment a colour is
    // nudged in Settings, the active preset is derived: it's the one whose body
    // the live config still matches exactly.

    // Recursively key-sorted copy, so two structurally equal snapshots always
    // stringify identically no matter what order the keys came off disk in.
    function _canon(v) {
        if (Array.isArray(v))
            return v.map(_canon);
        if (v && typeof v === "object") {
            const out = {};
            for (const k of Object.keys(v).sort())
                out[k] = _canon(v[k]);
            return out;
        }
        return v;
    }

    // Only the slices in `parts` count — a preset file's `name` / `saved`
    // metadata must not make two identical setups look different.
    function fingerprint(body) {
        const b = {};
        for (const key in parts)
            b[key] = (body && body[key] !== undefined) ? body[key] : null;
        return JSON.stringify(_canon(b));
    }

    readonly property string _liveFingerprint: fingerprint(capture())

    // Name of the preset the live config matches, "" once it has drifted from
    // every one of them.
    readonly property string activeName: {
        for (const n of names)
            if (fingerprint(presets[n]) === _liveFingerprint)
                return n;
        return "";
    }

    // --- naming -------------------------------------------------------------
    // A preset is addressed by its file name, so keep it to something that
    // survives the round-trip: no separators, no leading dot, no runaway length.
    function sanitize(name) {
        return (name ?? "").trim()
            .replace(/[^A-Za-z0-9 ._-]+/g, "-")
            .replace(/^[.\-]+/, "")
            .replace(/\s+/g, " ")
            .slice(0, 48)
            .trim();
    }

    function exists(name) {
        return presets[sanitize(name)] !== undefined;
    }

    // --- save / apply / delete ---------------------------------------------
    // Writes the live config out under `name`, replacing any preset already
    // there. Returns the sanitized name, or "" if nothing usable was left.
    function save(name) {
        // A preset already on disk is re-saved under the name it actually has —
        // sanitizing is for what the user just typed, and must not fork a
        // hand-named file into a second one on overwrite.
        const n = (name && presets[name] !== undefined) ? name : sanitize(name);
        if (n.length === 0)
            return "";
        const body = capture();
        body.name = n;
        body.saved = new Date().toISOString();
        _queue.push({ path: dir + "/" + n + ".json", body: JSON.stringify(body, null, 2) });
        if (!_writing)
            writer.next();
        return n;
    }

    // Re-save whatever is live under a preset's existing name.
    function update(name) { return save(name); }

    function apply(name) {
        const n = sanitize(name);
        const body = presets[n];
        if (!body)
            return false;
        // One level of undo: applying a preset replaces the whole setup, and
        // the thing it replaced may never have been saved anywhere.
        _undo = capture();
        restore(body);
        return true;
    }

    function remove(name) {
        const n = sanitize(name);
        if (n.length === 0 || presets[n] === undefined)
            return;
        rmProc.exec(["rm", "-f", "--", dir + "/" + n + ".json"]);
    }

    // --- undo ---------------------------------------------------------------
    // The configuration that was live before the last apply. Session-only —
    // a shell restart starts you on whatever is on disk.
    property var _undo: null
    readonly property bool canUndo: _undo !== null

    function undo() {
        if (_undo === null)
            return;
        const body = _undo;
        _undo = null;
        restore(body);
    }

    function forgetUndo() { _undo = null; }

    // --- disk ---------------------------------------------------------------
    function reload() { scanProc.running = true; }

    Component.onCompleted: reload()

    // Queued because a single Process can't run concurrent execs, and saving
    // twice in quick succession is an easy thing to do from the UI.
    property var _queue: []
    property bool _writing: false

    Process {
        id: writer

        function next() {
            if (root._queue.length === 0) {
                root._writing = false;
                root.reload();
                return;
            }
            root._writing = true;
            const job = root._queue.shift();
            exec({
                "environment": { "BODY": job.body, "F": job.path },
                "command": ["bash", "-c", 'mkdir -p "$(dirname "$F")" && printf "%s\\n" "$BODY" > "$F"']
            });
        }

        onExited: next()
    }

    Process {
        id: rmProc
        onExited: root.reload()
    }

    // cat every *.json in the presets dir, tagged by basename — the same
    // record/field separator framing Appearance uses for colour schemes, so
    // names with spaces survive.
    Process {
        id: scanProc
        command: ["bash", "-c",
            'mkdir -p "$0"; for f in "$0"/*.json; do [ -e "$f" ] || continue; ' +
            'printf "\\x1e%s\\x1f" "$(basename "$f" .json)"; cat "$f"; done',
            root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = {};
                for (const chunk of text.split("\x1e")) {
                    if (!chunk) continue;
                    const sep = chunk.indexOf("\x1f");
                    if (sep < 0) continue;
                    const name = chunk.slice(0, sep).trim();
                    const bodyText = chunk.slice(sep + 1).trim();
                    if (!name || !bodyText) continue;
                    try {
                        const body = JSON.parse(bodyText);
                        if (body && typeof body === "object")
                            found[name] = body;
                    } catch (e) {
                        console.warn("[Presets] bad preset", name, e);
                    }
                }
                root.presets = found;
            }
        }
    }

    // Drives presets from a niri keybind or a script:
    //   qs ipc call preset apply minimal
    IpcHandler {
        target: "preset"

        function list(): string { return root.names.join("\n"); }
        function current(): string { return root.activeName; }
        function save(name: string): string { return root.save(name); }
        function remove(name: string): void { root.remove(name); }
        function reload(): void { root.reload(); }
        function undo(): void { root.undo(); }

        function apply(name: string): string {
            if (!root.apply(name))
                return "no such preset: " + name;
            root.presetApplied(root.sanitize(name));
            return "";
        }
    }
}
