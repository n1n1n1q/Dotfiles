pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Global open/close + selected-section state for the settings window. Anything
// (a bar widget, a dashboard toggle, an IPC call) flips `open`; shell.qml keeps
// a single SettingsWindow whose visibility is bound to it.
Singleton {
    id: root

    property bool open: false
    // Slug of the nav section to show. Must match one of SettingsWindow's
    // `sections` entries.
    property string section: "welcome"

    function show(sec) {
        if (sec && sec.length > 0)
            section = sec;
        open = true;
    }

    function hide() {
        open = false;
    }

    function toggle(sec) {
        if (!open) {
            show(sec);
        } else if (sec && sec.length > 0 && sec !== section) {
            section = sec;
        } else {
            open = false;
        }
    }

    // Lets a niri keybind drive the window:
    //   qs ipc call settings toggle
    IpcHandler {
        target: "settings"

        function toggle(): void {
            root.toggle();
        }
        function open(section: string): void {
            root.show(section);
        }
        function close(): void {
            root.hide();
        }
    }
}
