pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.modules.bar

// One click-through surface per screen that hosts everything screen-wide and
// non-focus-stealing: the bar strip, the screen-edge frame decoration, the OSD
// pill and the notification toasts. All of them are keyboard-focus-free and
// share a single Wayland surface + GL context instead of one each.
//
// The window covers the whole screen (frame / OSD / toasts need that) but is
// anchored to only three edges, leaving the one opposite the bar free, so it
// can still reserve the bar's strip from tiled windows as an exclusive zone.
//
// (The desktop-widget layer stays separate — it sits on a lower layer.)
Scope {
    id: scope

    // Which outputs currently have a fullscreen window — the frame border and
    // the bar hide there (the black corner accents stay).
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
            readonly property string barEdge: BarConfig.edge
            readonly property real barZone: Theme.bar.height + (BarConfig.floating ? Theme.bar.margin : 0)

            // Overlay (not Top) so the black corner accents, toasts and OSD
            // still sit over a fullscreen window — the bar and the frame border
            // hide themselves there via `frameHidden`, matching the old split.
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:drawers"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "transparent"
            visible: true

            anchors {
                top: win.barEdge !== "bottom"
                bottom: win.barEdge !== "top"
                left: win.barEdge !== "right"
                right: win.barEdge !== "left"
            }
            implicitWidth: modelData.width
            implicitHeight: modelData.height
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: win.barZone

            // Frame + OSD are fully click-through; only the live toast stack and
            // the bar strip catch input.
            mask: Region {
                Region { item: notifView.listContent }
                Region { item: bar }
            }

            IdleInhibitor {
                window: win
                enabled: Caffeine.active
            }

            // Declared before FrameView so the frame's corner accents / fillets
            // paint over the bar's corners (they were a higher window before).
            Bar {
                id: bar
                modelData: win.modelData
                panelWindow: win
                hidden: win.frameHidden
            }

            FrameView { screenHidden: win.frameHidden }

            NotifView { id: notifView }

            OsdView { logic: osdLogic }
        }
    }
}
