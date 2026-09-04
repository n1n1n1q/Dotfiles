pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// One always-mapped, click-through overlay window per screen that hosts the
// screen-edge frame decoration, the OSD pill and the notification toasts — all
// of which are purely decorative / never take keyboard focus, so they can
// share a single Wayland surface + GL context instead of three.
//
// (The bar and the desktop-widget layer stay separate: the bar reserves an
// exclusive zone and the desktop sits on a lower layer.)
Scope {
    id: scope

    // Which outputs currently have a fullscreen window — the frame border and
    // shadow hide there (the black corner accents stay).
    readonly property var fullscreenScreens: {
        const s = new Set()
        for (const t of ToplevelManager.toplevels.values) {
            if (t.fullscreen) {
                for (const scr of t.screens) s.add(scr)
            }
        }
        return s
    }

    OsdLogic { id: osdLogic }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData

            readonly property bool frameHidden: scope.fullscreenScreens.has(modelData)

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:drawers"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            visible: true

            anchors { top: true; bottom: true; left: true; right: true }

            // Frame + OSD are fully click-through; only the live toast stack
            // catches input (same as the old per-window masks).
            mask: Region { item: notifView.listContent }

            FrameView { screenHidden: win.frameHidden }

            NotifView { id: notifView }

            OsdView { logic: osdLogic }
        }
    }
}
