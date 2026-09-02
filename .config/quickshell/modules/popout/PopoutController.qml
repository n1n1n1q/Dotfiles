pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Global state for the bar's anchored dropdown popouts (calendar / media /
// system monitor). A bar widget calls `toggle(name, screenX, widgetWidth,
// screenName)` with its own centre mapped to screen coordinates; one always-
// mapped BarPopout per screen (see BarPopout.qml) renders the matching card
// just below the bar, horizontally centred on the anchor and clamped to the
// screen. Mirrors SettingsController's shape (state singleton + IpcHandler).
Singleton {
    id: root

    // "" | "calendar" | "media" | "sysmon" | "traymenu"
    property string current: ""
    property real anchorX: 0
    property real anchorWidth: 0
    property string screenName: ""
    // Extra per-open data a card needs beyond the anchor (e.g. traymenu's
    // SystemTrayItem). Not cleared on close() - BarPopout keeps the last
    // non-empty one alive the same way it keeps `current` around, so the
    // card has something to render while it fades out.
    property var payload: null

    function open(name, x, w, screen, data) {
        // Nothing playing means the media card has nothing to draw - refuse the
        // popout outright, so the bar widget and the IPC entry point agree.
        if (name === "media" && !Media.activePlayer)
            return;
        anchorX = x ?? 0;
        anchorWidth = w ?? 0;
        screenName = screen ?? "";
        payload = data ?? null;
        current = name;
    }

    function close() {
        current = "";
    }

    function toggle(name, x, w, screen, data) {
        // Toggle shut only when it's truly the *same* popout — for `traymenu`
        // that means the same tray item, so right-clicking a different icon
        // switches the menu instead of just closing the open one.
        const samePayload = data === undefined || data === null || payload === data;
        if (current === name && screenName === (screen ?? "") && samePayload) {
            close();
            return;
        }
        open(name, x, w, screen, data);
    }

    // A player going away mid-popout leaves the card with nothing to show, so
    // take it down the same way `open` refuses to raise it in the first place.
    Connections {
        target: Media

        function onActivePlayerChanged() {
            if (root.current === "media" && Media.activePlayer === null)
                root.close();
        }
    }

    // qs ipc call popout toggle calendar
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
