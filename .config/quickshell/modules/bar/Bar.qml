import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

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
                radius: 0

                // The bar's own bottom edge doubles as the top run of the
                // screen frame (ScreenFrame.qml) - same color, same
                // thickness - so there's no separate strip glued on below
                // the bar and no seam/gap between the two.
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

                    // Left: focused-window title, doubles as the dashboard toggle.
                    WindowTitle {
                        anchors {
                            left: parent.left
                            leftMargin: Theme.spacing.medium
                            verticalCenter: parent.verticalCenter
                        }
                        parentWindow: barWindow
                        barHeight: barWindow.implicitHeight
                    }

                    // Centre: workspaces sit dead-centre of the bar, always -
                    // independent of the flanking clusters' widths.
                    WorkspaceIndicator {
                        id: workspaces
                        anchors.centerIn: parent
                        outputName: barWindow.modelData.name
                    }

                    // Left cluster: system stats + now-playing, merged onto one
                    // capsule, ending just left of the workspaces.
                    BarPill {
                        anchors {
                            right: workspaces.left
                            rightMargin: Theme.spacing.medium
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 0

                        SystemStats {}
                        MediaWidget {}
                    }

                    // Right cluster: clock + battery, merged onto one capsule,
                    // starting just right of the workspaces.
                    BarPill {
                        anchors {
                            left: workspaces.right
                            leftMargin: Theme.spacing.medium
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 0

                        TimeWidget {}
                        // VolumeWidget {}  // hidden for now (component kept)
                        BatteryWidget {}
                    }

                    // Right: system tray (no background). Its right edge sits
                    // the same distance in as WindowTitle's text does on the
                    // left: the left anchor margin plus WindowTitle's own hPad.
                    Tray {
                        anchors {
                            right: parent.right
                            rightMargin: Theme.spacing.medium + Theme.spacing.normal
                            verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
