import QtQuick
import Quickshell
import qs.config

// The top bar. Content is entirely data-driven from BarConfig (three anchored
// sections of groups). `BarConfig.style` moves the whole window to any screen
// edge (left/right rotate it into a vertical bar) and optionally detaches it
// into a floating pill. The layout is edited in a separate overlay
// (BarEditOverlay) so an edit session can never displace the real bar.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property ShellScreen modelData
            screen: modelData
            // Transparent so a floating pill's rounded corners show the
            // wallpaper through, not the window's own fill.
            color: "transparent"

            readonly property string edge: BarConfig.edge
            readonly property bool floating: BarConfig.floating
            readonly property bool vertical: BarConfig.vertical
            readonly property real thickness: Theme.bar.height
            readonly property real gap: floating ? Theme.bar.margin : 0

            anchors {
                top: edge !== "bottom"
                bottom: edge !== "top"
                left: edge !== "right"
                right: edge !== "left"
            }
            margins {
                top: edge !== "bottom" ? gap : 0
                bottom: edge !== "top" ? gap : 0
                left: edge !== "right" ? gap : 0
                right: edge !== "left" ? gap : 0
            }

            implicitWidth: thickness
            implicitHeight: thickness
            exclusiveZone: thickness + gap

            // Horizontal (top/bottom) fills width; vertical (left/right) is a
            // horizontal strip the length of the screen, rotated a quarter turn.
            Item {
                id: content
                anchors.fill: parent

                Item {
                    anchors.centerIn: parent
                    width: barWindow.vertical ? barWindow.height : content.width
                    height: barWindow.vertical ? barWindow.thickness : content.height
                    rotation: barWindow.vertical ? 90 : 0

                    // soft lift for the floating pill
                    Rectangle {
                        visible: barWindow.floating
                        anchors.fill: barStrip
                        anchors.margins: -5
                        radius: barStrip.radius + 5
                        color: Theme.popup.shadow
                        z: -1
                    }

                    Rectangle {
                        id: barStrip
                        anchors.fill: parent
                        color: Theme.bar.background
                        // A floating bar with "Floating corners" on is a proper
                        // pill — fully rounded end caps.
                        radius: (barWindow.floating && BarConfig.floatRounded)
                            ? Math.min(width, height) / 2 : 0

                        // The frame's shared run along the bar's inner edge —
                        // only when the frame is on and the bar is edge-docked.
                        Rectangle {
                            visible: BarConfig.frameEnabled && !barWindow.floating
                            height: Theme.frame.thickness
                            color: Theme.frame.color
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: barWindow.edge === "bottom" ? parent.top : undefined
                                bottom: barWindow.edge === "bottom" ? undefined : parent.bottom
                            }
                        }

                        BarSection {
                            align: "left"
                            groups: BarConfig.left
                            panelWindow: barWindow
                            screenName: barWindow.modelData.name
                        }
                        BarSection {
                            align: "center"
                            groups: BarConfig.center
                            panelWindow: barWindow
                            screenName: barWindow.modelData.name
                        }
                        BarSection {
                            align: "right"
                            groups: BarConfig.right
                            panelWindow: barWindow
                            screenName: barWindow.modelData.name
                        }
                    }
                }
            }
        }
    }
}
