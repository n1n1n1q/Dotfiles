pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Desktop widget layout. A flat list of widget instances, each pinned to a
// screen at an x/y with a per-type `props` bag. Persisted as JSON at
// ~/.config/quickshell/desktop.json (hand-editable; written back by
// Settings > Widgets). `editMode` is runtime-only — it puts the desktop layer
// into drag mode and is never saved.
Singleton {
    id: root

    // [{ id, type, screen, x, y, props }]   screen: an output name or "all"
    readonly property var widgets: adapter.widgets
    property bool editMode: false
    property bool ready: false

    // Set to a freshly-added widget's id while the user is positioning it:
    // the widget follows the pointer on the desktop until a click drops it
    // (Esc removes it). Cross-window native drag isn't routed to layer
    // surfaces in niri, so this "pick from the grid, then place" flow stands
    // in for dragging a tile straight onto the wallpaper.
    property string grabbedId: ""
    // The widget whose edit chrome (outline / delete / resize) is shown.
    property string selectedId: ""

    // --- edit transaction (Enter commits, Esc / workspace-switch cancels) --
    property var _snapshot: null

    function beginEdit() {
        _snapshot = JSON.stringify(adapter.widgets);
        selectedId = "";
        grabbedId = "";
        editMode = true;
    }
    function commitEdit() {
        _snapshot = null;
        selectedId = "";
        grabbedId = "";
        editMode = false;
    }
    function cancelEdit() {
        if (_snapshot !== null) {
            adapter.widgets = JSON.parse(_snapshot);
            _snapshot = null;
        }
        selectedId = "";
        grabbedId = "";
        editMode = false;
    }

    // metadata for the settings UI
    readonly property var catalogue: [
        { type: "clock", name: "Clock",        icon: "󰅐", desc: "Time and date" },
        { type: "stats", name: "System stats", icon: "󰾆", desc: "CPU / RAM / GPU gauges" },
        { type: "media", name: "Media",        icon: "󰝚", desc: "Now playing + transport" }
    ]

    function catalogueEntry(type) {
        return catalogue.find(c => c.type === type) ?? ({ type: type, name: type, icon: "󰋙", desc: "" });
    }

    function defaultsFor(type) {
        if (type === "clock")
            return { format24: true, showDate: true, fontScale: 1.0, align: "center" };
        if (type === "stats")
            return { showCpu: true, showRam: true, showGpu: false, scale: 1.0 };
        if (type === "media")
            return { scale: 1.0 };
        return {};
    }

    // --- editing (deep-clone → mutate → reassign, like BarConfig) ---------
    function _clone() { return JSON.parse(JSON.stringify(adapter.widgets)); }
    function _commit(a) { adapter.widgets = a; }
    function _uid() {
        return "w" + Date.now().toString(36) + Math.floor(Math.random() * 1e4).toString(36);
    }
    function _find(a, id) { return a.find(w => w.id === id); }

    function add(type, screen) {
        return addAt(type, screen, 96, 96);
    }
    function addAt(type, screen, x, y) {
        if (!type) return "";
        const a = _clone();
        const id = _uid();
        a.push({
            id: id, type: type, screen: screen ?? "",
            x: Math.round(x), y: Math.round(y), props: defaultsFor(type)
        });
        _commit(a);
        return id;
    }

    // Pick a widget from the grid: add it centred on the target display and
    // hand it to the desktop layer to follow the pointer until placed.
    function placeNew(type, screen) {
        if (!type) return;
        if (!editMode)
            beginEdit();
        let scr = (screen && screen !== "all") ? screen : "";
        if (scr === "" && Quickshell.screens.length > 0)
            scr = Quickshell.screens[0].name;
        const s = Quickshell.screens.find(o => o.name === scr);
        grabbedId = addAt(type, scr, s ? s.width / 2 - 80 : 200, s ? s.height / 2 - 40 : 160);
    }
    function placeCommit(x, y) {
        if (grabbedId === "") return;
        move(grabbedId, x, y);
        selectedId = grabbedId;
        grabbedId = "";
    }
    function placeCancel() {
        if (grabbedId === "") return;
        remove(grabbedId);
        grabbedId = "";
    }
    function remove(id) {
        _commit(_clone().filter(w => w.id !== id));
    }
    function move(id, x, y) {
        const a = _clone();
        const w = _find(a, id);
        if (!w) return;
        w.x = Math.round(x);
        w.y = Math.round(y);
        _commit(a);
    }
    function setScreen(id, screen) {
        const a = _clone();
        const w = _find(a, id);
        if (!w) return;
        w.screen = screen;
        _commit(a);
    }
    function setProp(id, key, val) {
        const a = _clone();
        const w = _find(a, id);
        if (!w) return;
        if (!w.props) w.props = {};
        w.props[key] = val;
        _commit(a);
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/desktop.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.ready = true
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                writeAdapter();
                root.ready = true;
            }
        }

        JsonAdapter {
            id: adapter
            property var widgets: []
        }
    }
}
