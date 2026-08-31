pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Data-driven bar layout. The bar is three ordered lists of *groups*
// (`left` / `center` / `right`); each group is a pill that optionally draws a
// shared background and holds an ordered list of widget ids:
//
//   { "background": true, "widgets": ["clock", "battery"] }
//
// Persisted as JSON at ~/.config/quickshell/bar.json — hand-editable, and
// written back by the Settings > Bar editor through the helpers below.
Singleton {
    id: root

    readonly property var left: adapter.left
    readonly property var center: adapter.center
    readonly property var right: adapter.right
    property bool ready: false

    // --- bar / frame style ---------------------------------------------
    // Persisted in bar.json under `style`. `edge` moves the whole bar to any
    // screen edge (left/right become a vertical bar); `floating` detaches it
    // into a pill; the frame trio toggles the ScreenFrame decoration.
    readonly property var defaultStyle: ({
        "edge": "top",          // top | bottom | left | right
        "floating": false,
        "floatRounded": true,   // rounded corners on the floating pill
        "frame": true,          // draw the ScreenFrame border
        "rounded": true,        // rounded corner transitions (frame or bare)
        "blackCorners": true    // the black screen-rounder accents
    })
    readonly property string edge: adapter.style?.edge ?? "top"
    readonly property bool floating: adapter.style?.floating ?? false
    readonly property bool floatRounded: adapter.style?.floatRounded ?? true
    // A floating bar is its own detached pill — the screen frame is forced off.
    readonly property bool frameEnabled: !floating && (adapter.style?.frame ?? true)
    readonly property bool frameRounded: adapter.style?.rounded ?? true
    readonly property bool blackCorners: adapter.style?.blackCorners ?? true
    readonly property bool vertical: edge === "left" || edge === "right"

    // --- popout cards ---------------------------------------------------
    // Style for the bar's dropdown cards, persisted in bar.json under
    // `popouts`. Only the media card has a knob so far: which of MediaLayout's
    // four now-playing layouts it draws.
    readonly property var defaultPopouts: ({ "mediaLayout": "regular" })
    readonly property string mediaLayout: adapter.popouts?.mediaLayout ?? "regular"

    function setPopout(key, val) {
        const p = JSON.parse(JSON.stringify(adapter.popouts ?? defaultPopouts));
        p[key] = val;
        adapter.popouts = p;
    }

    function setStyle(key, val) {
        const s = JSON.parse(JSON.stringify(adapter.style ?? defaultStyle));
        s[key] = val;
        adapter.style = s;
    }
    function resetStyle() { adapter.style = JSON.parse(JSON.stringify(defaultStyle)); }

    // --- preset slice -------------------------------------------------------
    // The whole of bar.json, handed to / taken back from `Presets`. `editMode`
    // is runtime-only and deliberately left out: a preset restores a layout,
    // not a half-finished edit session.
    function snapshot() {
        return JSON.parse(JSON.stringify({
            "left": adapter.left,
            "center": adapter.center,
            "right": adapter.right,
            "style": adapter.style ?? defaultStyle,
            "popouts": adapter.popouts ?? defaultPopouts
        }));
    }

    function applySnapshot(o) {
        if (!o) return;
        // An in-flight edit holds a snapshot of its own; cancelling it now
        // would put the pre-preset layout back a moment later.
        if (editMode) commitEdit();
        if (o.left) adapter.left = JSON.parse(JSON.stringify(o.left));
        if (o.center) adapter.center = JSON.parse(JSON.stringify(o.center));
        if (o.right) adapter.right = JSON.parse(JSON.stringify(o.right));
        // Style keys the preset omits fall back to the defaults rather than
        // lingering from the setup being replaced.
        if (o.style)
            adapter.style = Object.assign(JSON.parse(JSON.stringify(defaultStyle)), o.style);
        if (o.popouts)
            adapter.popouts = Object.assign(JSON.parse(JSON.stringify(defaultPopouts)), o.popouts);
    }

    // --- live "edit on the bar" mode -------------------------------------
    // A temporary mode (Settings > Bar, or `qs ipc call bar edit`): bar
    // widgets jiggle, click one to pick it up, click an insert marker to drop
    // it. Enter commits, Esc cancels the whole session.
    property bool editMode: false
    property var _snap: null
    // null
    //  | { kind: "new",   widgetId }
    //  | { kind: "move",  widgetId, section, groupIndex, widgetIndex }
    //  | { kind: "group", section, groupIndex }
    property var grab: null

    function beginEdit() {
        _snap = JSON.stringify({ l: adapter.left, c: adapter.center, r: adapter.right });
        grab = null;
        editMode = true;
    }
    function commitEdit() {
        _snap = null;
        grab = null;
        editMode = false;
    }
    function cancelEdit() {
        if (_snap !== null) {
            const s = JSON.parse(_snap);
            adapter.left = s.l;
            adapter.center = s.c;
            adapter.right = s.r;
            _snap = null;
        }
        grab = null;
        editMode = false;
    }

    function pickUpWidget(section, gi, wi) {
        const w = (adapter[section][gi]?.widgets ?? [])[wi];
        if (w === undefined) return;
        grab = { kind: "move", widgetId: w, section: section, groupIndex: gi, widgetIndex: wi };
    }
    function pickUpGroup(section, gi) {
        if (!adapter[section][gi]) return;
        grab = { kind: "group", section: section, groupIndex: gi };
    }
    function pickNewWidget(widgetId) {
        grab = { kind: "new", widgetId: widgetId };
    }
    function cancelGrab() { grab = null; }

    // targetKind: "widget-gap" (a=groupIndex, b=widgetIndex) | "new-group" (a=groupIndex)
    //           | "remove" (drop back onto the pool dock)
    function placeGrab(targetKind, section, a, b) {
        const g = grab;
        if (!g) return;
        grab = null;
        if (targetKind === "remove") {
            if (g.kind === "move") removeWidget(g.section, g.groupIndex, g.widgetIndex);
            else if (g.kind === "group") removeGroup(g.section, g.groupIndex);
            return;
        }
        if (g.kind === "group") {
            // a group only drops between groups
            if (targetKind === "new-group")
                moveGroupAcross(g.section, g.groupIndex, section, a);
            return;
        }
        if (g.kind === "new") {
            if (targetKind === "widget-gap") addWidgetAt(section, a, b, g.widgetId);
            else addWidgetNewGroup(section, a, g.widgetId);
            return;
        }
        // kind === "move"
        if (targetKind === "widget-gap")
            moveWidgetAcross(g.section, g.groupIndex, g.widgetIndex, section, a, b);
        else
            moveWidgetToNewGroup(g.section, g.groupIndex, g.widgetIndex, section, a);
    }

    // --- widget catalogue (metadata for the Settings UI) ------------------
    readonly property var catalogue: [
        { id: "windowTitle", name: "Window title",  desc: "Focused window's app id + title; opens the dashboard on click", icon: "󰖯" },
        { id: "workspaces",  name: "Workspaces",    desc: "niri workspace indicator — click a slot to switch",             icon: "󰇘" },
        { id: "systemStats", name: "System monitor", desc: "CPU / RAM / GPU ring gauges with tinted percentages",           icon: "󰾆" },
        { id: "media",       name: "Media",         desc: "Now-playing title with a play / pause gauge",                   icon: "󰝚" },
        { id: "clock",       name: "Clock",         desc: "Time and date",                                                 icon: "󰅐" },
        { id: "battery",     name: "Battery",       desc: "Charge %, time remaining, charging pulse",                       icon: "󰁽" },
        { id: "volume",      name: "Volume",        desc: "Output level gauge — scroll to change, click to mute",           icon: "󰕾" },
        { id: "connectivity", name: "Connectivity", desc: "Wi‑Fi, Bluetooth and sound glyphs; each opens its Settings page", icon: "󰤨" },
        { id: "tray",        name: "System tray",   desc: "StatusNotifier icons from running apps",                        icon: "󰧜" }
    ]

    function widget(id) {
        return catalogue.find(w => w.id === id) ?? ({ id: id, name: id, desc: "", icon: "󰋙" });
    }
    function widgetName(id) { return widget(id).name; }
    function widgetIcon(id) { return widget(id).icon; }

    // --- defaults (mirror the hand-built bar) -----------------------------
    readonly property var defaults: ({
        "left":   [ { "background": false, "widgets": ["windowTitle"] } ],
        "center": [
            { "background": true, "widgets": ["systemStats", "media"] },
            { "background": true, "pin": true, "widgets": ["workspaces"] },
            { "background": true, "widgets": ["clock", "battery"] }
        ],
        "right":  [ { "background": false, "widgets": ["connectivity", "tray"] } ]
    })

    function reset() {
        adapter.left = JSON.parse(JSON.stringify(defaults.left));
        adapter.center = JSON.parse(JSON.stringify(defaults.center));
        adapter.right = JSON.parse(JSON.stringify(defaults.right));
    }

    // --- editing helpers (each reassigns a whole section -> autosaves) -----
    function _clone(section) { return JSON.parse(JSON.stringify(adapter[section])); }
    function _commit(section, arr) { adapter[section] = arr; }
    function _swap(arr, i, j) { const t = arr[i]; arr[i] = arr[j]; arr[j] = t; }

    function addGroup(section) {
        const a = _clone(section);
        a.push({ background: true, widgets: [] });
        _commit(section, a);
    }
    function removeGroup(section, gi) {
        const a = _clone(section);
        a.splice(gi, 1);
        _commit(section, a);
    }
    function moveGroup(section, gi, dir) {
        const a = _clone(section);
        const j = gi + dir;
        if (j < 0 || j >= a.length) return;
        _swap(a, gi, j);
        _commit(section, a);
    }
    // Move a group to the start/end of another section.
    function shiftGroup(fromSection, gi, toSection, atEnd) {
        const from = _clone(fromSection);
        const g = from.splice(gi, 1)[0];
        const to = _clone(toSection);
        if (atEnd) to.push(g); else to.unshift(g);
        adapter[fromSection] = from;
        adapter[toSection] = to;
    }
    function setGroupBackground(section, gi, on) {
        const a = _clone(section);
        a[gi].background = on;
        _commit(section, a);
    }
    // Pin one group to the centre of its region — at most one per section, so
    // enabling clears the others.
    function setGroupPin(section, gi, on) {
        const a = _clone(section);
        for (let i = 0; i < a.length; i++)
            a[i].pin = on && i === gi;
        _commit(section, a);
    }
    function addWidget(section, gi, widgetId) {
        const a = _clone(section);
        a[gi].widgets.push(widgetId);
        _commit(section, a);
    }
    function removeWidget(section, gi, wi) {
        const a = _clone(section);
        a[gi].widgets.splice(wi, 1);
        _commit(section, a);
    }
    function moveWidget(section, gi, wi, dir) {
        const a = _clone(section);
        const j = wi + dir;
        if (j < 0 || j >= a[gi].widgets.length) return;
        _swap(a[gi].widgets, wi, j);
        _commit(section, a);
    }

    // --- drag-and-drop editor helpers ------------------------------------
    // Drop empty, non-pinned groups from a section array (mutates in place).
    function _prune(arr) {
        for (let i = arr.length - 1; i >= 0; i--)
            if ((arr[i].widgets ?? []).length === 0 && !arr[i].pin)
                arr.splice(i, 1);
        return arr;
    }

    // Insert a fresh empty group at an index (generalises addGroup).
    function insertGroup(section, atIndex) {
        const a = _clone(section);
        const i = Math.max(0, Math.min(atIndex, a.length));
        a.splice(i, 0, { background: true, widgets: [] });
        _commit(section, a);
    }

    // Move a whole group to an arbitrary index, within or across sections.
    function moveGroupAcross(fromSection, gi, toSection, toIndex) {
        if (fromSection === toSection) {
            const a = _clone(fromSection);
            if (gi < 0 || gi >= a.length) return;
            const g = a.splice(gi, 1)[0];
            let j = gi < toIndex ? toIndex - 1 : toIndex;
            j = Math.max(0, Math.min(j, a.length));
            a.splice(j, 0, g);
            _commit(fromSection, a);
            return;
        }
        const from = _clone(fromSection);
        const to = _clone(toSection);
        if (gi < 0 || gi >= from.length) return;
        const g = from.splice(gi, 1)[0];
        const j = Math.max(0, Math.min(toIndex, to.length));
        to.splice(j, 0, g);
        adapter[fromSection] = from;
        adapter[toSection] = to;
    }

    // Insert a widget id at a specific slot in a group (wi < 0 = append).
    function addWidgetAt(section, gi, wi, widgetId) {
        const a = _clone(section);
        if (!a[gi]) return;
        if (!a[gi].widgets) a[gi].widgets = [];
        const i = wi < 0 ? a[gi].widgets.length
            : Math.max(0, Math.min(wi, a[gi].widgets.length));
        a[gi].widgets.splice(i, 0, widgetId);
        _commit(section, a);
    }

    // Move one widget to a slot in another (or the same) group; toWi < 0 = append.
    // Emptied source groups are pruned.
    function moveWidgetAcross(fromSection, fromGi, fromWi, toSection, toGi, toWi) {
        if (fromSection === toSection) {
            const a = _clone(fromSection);
            if (!a[fromGi] || !a[toGi]) return;
            const id = a[fromGi].widgets.splice(fromWi, 1)[0];
            if (id === undefined) return;
            if (!a[toGi].widgets) a[toGi].widgets = [];
            let j = toWi < 0 ? a[toGi].widgets.length : toWi;
            if (fromGi === toGi && fromWi < j) j--;
            j = Math.max(0, Math.min(j, a[toGi].widgets.length));
            a[toGi].widgets.splice(j, 0, id);
            _prune(a);
            _commit(fromSection, a);
            return;
        }
        const from = _clone(fromSection);
        const to = _clone(toSection);
        if (!from[fromGi] || !to[toGi]) return;
        const id = from[fromGi].widgets.splice(fromWi, 1)[0];
        if (id === undefined) return;
        if (!to[toGi].widgets) to[toGi].widgets = [];
        const j = toWi < 0 ? to[toGi].widgets.length
            : Math.max(0, Math.min(toWi, to[toGi].widgets.length));
        to[toGi].widgets.splice(j, 0, id);
        _prune(from);
        adapter[fromSection] = from;
        adapter[toSection] = to;
    }

    // Move one widget into a brand-new group at a group index in some section.
    function moveWidgetToNewGroup(fromSection, fromGi, fromWi, toSection, toIndex) {
        if (fromSection === toSection) {
            const a = _clone(fromSection);
            if (!a[fromGi]) return;
            const id = a[fromGi].widgets[fromWi];
            if (id === undefined) return;
            a[fromGi].widgets.splice(fromWi, 1);
            const j = Math.max(0, Math.min(toIndex, a.length));
            a.splice(j, 0, { background: a[fromGi] ? (a[fromGi].background ?? true) : true, widgets: [id] });
            _prune(a);
            _commit(fromSection, a);
            return;
        }
        const from = _clone(fromSection);
        if (!from[fromGi]) return;
        const id = from[fromGi].widgets[fromWi];
        if (id === undefined) return;
        from[fromGi].widgets.splice(fromWi, 1);
        _prune(from);
        const to = _clone(toSection);
        const j = Math.max(0, Math.min(toIndex, to.length));
        to.splice(j, 0, { background: true, widgets: [id] });
        adapter[fromSection] = from;
        adapter[toSection] = to;
    }

    // Add a catalogue widget into a new group at a group index.
    function addWidgetNewGroup(section, atIndex, widgetId) {
        const a = _clone(section);
        const i = Math.max(0, Math.min(atIndex, a.length));
        a.splice(i, 0, { background: true, widgets: [widgetId] });
        _commit(section, a);
    }

    IpcHandler {
        target: "bar"
        function edit(): void { root.beginEdit(); }
        function done(): void { root.commitEdit(); }
        function cancel(): void { root.cancelEdit(); }
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/bar.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.ready = true
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.reset();
                writeAdapter();
                root.ready = true;
            }
        }

        JsonAdapter {
            id: adapter
            property var left: root.defaults.left
            property var center: root.defaults.center
            property var right: root.defaults.right
            property var style: root.defaultStyle
            property var popouts: root.defaultPopouts
        }
    }
}
