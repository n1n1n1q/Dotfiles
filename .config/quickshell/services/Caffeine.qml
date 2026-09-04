pragma Singleton

import Quickshell
import Quickshell.Io

// "Keep awake" / anti-sleep. While `active`, the shell holds a Wayland idle
// inhibitor (`idle-inhibit-unstable-v1`) — the compositor won't blank /
// DPMS-off / auto-lock, and the shell's own idle-lock (`Lock.qml`'s
// IdleMonitor, which also checks `Caffeine.active`) stays put too. The
// inhibitor itself is attached to the always-mapped Drawers window (see
// Drawers.qml) rather than a dedicated 0×0 surface — one fewer Wayland
// surface / GL context / render thread at idle.
//
// Deliberately NOT persisted: a keep-awake that survived a reboot would be a
// nasty surprise. Toggle it from the dashboard tile or `qs ipc call caffeine`.
Singleton {
    id: root

    property bool active: false
    property date since: new Date()

    onActiveChanged: if (active) since = new Date()

    function toggle() { root.active = !root.active; }
    function enable() { root.active = true; }
    function disable() { root.active = false; }

    IpcHandler {
        target: "caffeine"
        function toggle(): void { root.toggle(); }
        function on(): void { root.enable(); }
        function off(): void { root.disable(); }
        function isOn(): bool { return root.active; }
    }
}
