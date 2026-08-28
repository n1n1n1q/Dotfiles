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

    // --- widget catalogue (metadata for the Settings UI) ------------------
    readonly property var catalogue: [
        { id: "windowTitle", name: "Window title",  desc: "Focused window's app id + title; opens the dashboard on click", icon: "󰖯" },
        { id: "workspaces",  name: "Workspaces",    desc: "niri workspace indicator — click a slot to switch",             icon: "󰇘" },
        { id: "systemStats", name: "System monitor", desc: "CPU / RAM / GPU ring gauges with tinted percentages",           icon: "󰾆" },
        { id: "media",       name: "Media",         desc: "Now-playing title with a play / pause gauge",                   icon: "󰝚" },
        { id: "clock",       name: "Clock",         desc: "Time and date",                                                 icon: "󰅐" },
        { id: "battery",     name: "Battery",       desc: "Charge %, time remaining, charging pulse",                       icon: "󰁽" },
        { id: "volume",      name: "Volume",        desc: "Output level gauge — scroll to change, click to mute",           icon: "󰕾" },
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
        "right":  [ { "background": false, "widgets": ["tray"] } ]
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
        }
    }
}
