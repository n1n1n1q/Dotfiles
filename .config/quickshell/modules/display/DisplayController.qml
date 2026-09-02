pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Windows-"Win+P"-style display-mode switcher. Drives niri's per-output
// `off` flag through NiriConfig (so it needs the output blocks split — see
// Settings › Display). niri 26.04 has no output mirroring, so there's no
// "Duplicate" mode; the choices are Extend / Internal only / External only.
//
//   qs ipc call display menu|extend|internal|external|mode
Singleton {
    id: root

    // Popup visibility, mirroring LauncherController/PickerController's shape.
    property string openOn: ""            // screen name, "" = closed
    readonly property bool open: openOn.length > 0

    readonly property bool ready: NiriConfig.outputsSplit

    // --- output roles --------------------------------------------------
    function _isInternal(name) {
        return /^(eDP|LVDS|DSI)-/i.test(String(name || ""));
    }
    readonly property var connectedOutputs:
        (NiriConfig.outputs || []).filter(o => o.connected)
    readonly property var internalOutputs:
        connectedOutputs.filter(o => root._isInternal(o.name))
    readonly property var externalOutputs:
        connectedOutputs.filter(o => !root._isInternal(o.name))

    readonly property bool hasInternal: internalOutputs.length > 0
    readonly property bool hasExternal: externalOutputs.length > 0
    // Extend / single-external only make sense with a second display attached.
    readonly property bool multiMonitor: connectedOutputs.length > 1

    // What's live right now: everything on -> extend; only one side on -> that.
    readonly property string currentMode: {
        const on = connectedOutputs.filter(o => !o.off);
        if (on.length === 0) return "none";
        const anyIntOff = internalOutputs.some(o => o.off);
        const anyExtOff = externalOutputs.some(o => o.off);
        const anyIntOn = internalOutputs.some(o => !o.off);
        const anyExtOn = externalOutputs.some(o => !o.off);
        if (anyIntOn && anyExtOn && !anyIntOff && !anyExtOff) return "extend";
        if (anyIntOn && !anyExtOn) return "internal";
        if (anyExtOn && !anyIntOn) return "external";
        return "custom";
    }

    // --- apply -------------------------------------------------------
    function _set(name, on) {
        NiriConfig.setOutput(name, "enabled", on ? 1 : 0);
    }
    // niri applies output changes one at a time (setProc is single-flight),
    // so chain them: NiriConfig.busy clears on each `setProc.onExited`.
    property var _queue: []
    function _drain() {
        if (root._queue.length === 0 || NiriConfig.busy)
            return;
        const job = root._queue.shift();
        root._set(job.name, job.on);
    }
    Connections {
        target: NiriConfig
        function onBusyChanged() { if (!NiriConfig.busy) root._drain(); }
    }

    function apply(mode) {
        if (!root.ready)
            return;
        let jobs = [];
        if (mode === "internal") {
            root.internalOutputs.forEach(o => jobs.push({ name: o.name, on: true }));
            root.externalOutputs.forEach(o => jobs.push({ name: o.name, on: false }));
        } else if (mode === "external") {
            if (!root.hasExternal) return;
            root.externalOutputs.forEach(o => jobs.push({ name: o.name, on: true }));
            root.internalOutputs.forEach(o => jobs.push({ name: o.name, on: false }));
        } else { // extend
            root.connectedOutputs.forEach(o => jobs.push({ name: o.name, on: true }));
        }
        // Drop no-ops so a single-monitor "extend" doesn't rewrite the file.
        jobs = jobs.filter(j => {
            const o = root.connectedOutputs.find(x => x.name === j.name);
            return o && (!!o.off === j.on);
        });
        root._queue = jobs;
        root._drain();
    }

    // --- popup control --------------------------------------------------
    function _preferredScreen() {
        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "";
    }
    function show(screenName) {
        NiriConfig.refreshOutputs();
        root.openOn = (screenName && screenName.length > 0)
            ? screenName : root._preferredScreen();
    }
    function hide() { root.openOn = ""; }
    function toggle(screenName) {
        if (root.open) root.hide();
        else root.show(screenName);
    }

    IpcHandler {
        target: "display"
        function menu(): void { root.toggle(""); }
        function extend(): void { root.apply("extend"); }
        function internal(): void { root.apply("internal"); }
        function external(): void { root.apply("external"); }
        function mode(): string { return root.currentMode; }
        function close(): void { root.hide(); }
    }
}
