pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// "Keep awake" / anti-sleep. While `active`, holds a Wayland idle inhibitor
// (`idle-inhibit-unstable-v1`) on a tiny always-mapped surface — the compositor
// won't blank / DPMS-off / auto-lock, and the shell's own idle-lock
// (`Lock.qml`'s IdleMonitor, which also checks `Caffeine.active`) stays put too.
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

    IdleInhibitor {
        enabled: root.active
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            exclusiveZone: 0
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "quickshell:caffeine"
        }
    }

    IpcHandler {
        target: "caffeine"
        function toggle(): void { root.toggle(); }
        function on(): void { root.enable(); }
        function off(): void { root.disable(); }
        function isOn(): bool { return root.active; }
    }
}
