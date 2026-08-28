import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// The top bar. Its content is entirely data-driven from BarConfig (three
// anchored sections of groups); the pieces here are just the window, the frame
// edge and the section anchors. Edit the layout in Settings > Bar or in
// ~/.config/quickshell/bar.json.
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property ShellScreen modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: Theme.bar.height
            exclusiveZone: implicitHeight

            Rectangle {
                anchors.fill: parent
                color: Theme.bar.background

                // The bar's own bottom edge doubles as the top run of the
                // screen frame (ScreenFrame.qml) - same color, same thickness.
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: Theme.frame.thickness
                    color: Theme.frame.color
                }

                Item {
                    anchors.fill: parent

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
