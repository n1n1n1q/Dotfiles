import QtQuick
import Quickshell
import qs.config
import qs.widgets

// The bar — a strip laid along BarConfig.edge inside the shared Drawers window
// (one full-screen surface per screen). The Drawers window owns the exclusive
// zone that keeps tiled windows clear of it; this is purely the visual + input
// content. Content is entirely data-driven from BarConfig (three anchored
// sections of groups). `BarConfig.style` moves the strip to any screen edge
// (left/right rotate it into a vertical bar) and optionally detaches it into a
// floating pill. The layout is edited in a separate overlay (BarEditOverlay).
Item {
    id: root

    // Passed by the Drawers host.
    required property ShellScreen modelData
    property var panelWindow: null
    // True while a fullscreen window covers this screen (bar hides, matching
    // its old WlrLayer.Top behaviour of being occluded by fullscreen).
    property bool hidden: false

    readonly property string edge: BarConfig.edge
    readonly property bool floating: BarConfig.floating
    readonly property bool vertical: BarConfig.vertical
    readonly property real thickness: Theme.bar.height
    readonly property real gap: floating ? Theme.bar.margin : 0

    visible: !hidden

    // Plain geometry bindings rather than toggled anchors — `edge` can change at
    // runtime and flipping an anchor to/from `undefined` leaves Qt with stale
    // anchor state (the same trap BarSection's pin hits).
    x: edge === "right" ? parent.width - thickness - gap : gap
    y: edge === "bottom" ? parent.height - thickness - gap : gap
    width: vertical ? thickness : parent.width - gap * 2
    height: vertical ? parent.height - gap * 2 : thickness

    // Horizontal (top/bottom) fills width; vertical (left/right) is a
    // horizontal strip the length of the screen, rotated a quarter turn.
    Item {
        id: content
        anchors.fill: parent

        Item {
            anchors.centerIn: parent
            width: root.vertical ? content.height : content.width
            height: root.vertical ? root.thickness : content.height
            rotation: root.vertical ? 90 : 0

            // soft lift for the floating pill (a detached pill always gets it;
            // the docked bar's inward shadow is the frame decoration's
            // InnerShadow, driven by BarConfig.style.shadow)
            SoftShadow {
                target: barStrip
                radius: barStrip.radius
                visible: root.floating
            }

            Rectangle {
                id: barStrip
                anchors.fill: parent
                color: Theme.bar.background
                // A floating bar with "Floating corners" on is a proper pill —
                // fully rounded end caps.
                radius: (root.floating && BarConfig.floatRounded)
                    ? Math.min(width, height) / 2 : 0

                // The frame's shared run along the bar's inner edge — only when
                // the frame is on and the bar is edge-docked.
                Rectangle {
                    visible: BarConfig.frameEnabled && !root.floating
                    height: Theme.frame.thickness
                    color: Theme.frame.color
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: root.edge === "bottom" ? parent.top : undefined
                        bottom: root.edge === "bottom" ? undefined : parent.bottom
                    }
                }

                BarSection {
                    align: "left"
                    groups: BarConfig.left
                    panelWindow: root.panelWindow
                    screenName: root.modelData.name
                }
                BarSection {
                    align: "center"
                    groups: BarConfig.center
                    panelWindow: root.panelWindow
                    screenName: root.modelData.name
                }
                BarSection {
                    align: "right"
                    groups: BarConfig.right
                    panelWindow: root.panelWindow
                    screenName: root.modelData.name
                }
            }
        }
    }
}
