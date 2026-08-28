pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Global state for the bar's anchored dropdown popouts (calendar / media /
// system monitor). A bar widget calls `toggle(name, screenX, widgetWidth,
// screenName)` with its own centre mapped to screen coordinates; one always-
// mapped BarPopout per screen (see BarPopout.qml) renders the matching card
// just below the bar, horizontally centred on the anchor and clamped to the
// screen. Mirrors SettingsController's shape (state singleton + IpcHandler).
Singleton {
    id: root

    // "" | "calendar" | "media" | "sysmon"
    property string current: ""
    property real anchorX: 0
    property real anchorWidth: 0
    property string screenName: ""

    function open(name, x, w, screen) {
        anchorX = x ?? 0;
        anchorWidth = w ?? 0;
        screenName = screen ?? "";
        current = name;
    }

    function close() {
        current = "";
    }

    function toggle(name, x, w, screen) {
        if (current === name && screenName === (screen ?? "")) {
            close();
            return;
        }
        open(name, x, w, screen);
    }

    // qs -c quickshell ipc call popout toggle calendar
    IpcHandler {
        target: "popout"

        function toggle(name: string): void {
            root.toggle(name, 0, 0, "");
        }
        function open(name: string): void {
            root.open(name, 0, 0, "");
        }
        function close(): void {
            root.close();
        }
    }
}
