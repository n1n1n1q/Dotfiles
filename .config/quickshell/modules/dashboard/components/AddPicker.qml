import QtQuick
import QtQuick.Layouts
import qs.config

// The list of things not currently in the panel, dropped open by the "+" cell
// at the end of the quick-settings grid / slider stack. Click one to append it.
// In-flow rather than a floating popup, so it can't land off the panel.
ColumnLayout {
    id: picker

    property string kind: "toggles"
    property var entries: []
    property bool open: false

    signal picked(string id)

    Layout.fillWidth: true
    spacing: 0

    // Collapsing to zero height keeps it out of the layout entirely when shut.
    visible: open

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: col.implicitHeight + Theme.spacing.normal * 2
        radius: Theme.rounding.medium
        color: Theme.colors.surface0
        border.width: 1
        border.color: Theme.colors.border

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top
                      margins: Theme.spacing.normal }
            spacing: Theme.spacing.small

            Text {
                Layout.fillWidth: true
                text: picker.entries.length > 0
                    ? "Add to the panel" : "Everything is already in the panel"
                font.family: Theme.font.main
                font.pointSize: Theme.font.tiny
                color: Theme.colors.textTertiary
            }

            Flow {
                Layout.fillWidth: true
                spacing: Theme.spacing.tiny

                Repeater {
                    model: picker.entries

                    delegate: Rectangle {
                        id: chip
                        required property var modelData

                        implicitWidth: chipRow.implicitWidth + Theme.spacing.normal * 2
                        implicitHeight: 30
                        radius: Theme.rounding.small
                        color: chipMouse.containsMouse
                            ? Theme.colors.accent : Theme.colors.surface
                        border.width: 1
                        border.color: chipMouse.containsMouse
                            ? Theme.colors.accent : Theme.colors.border

                        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: Theme.spacing.tiny

                            Text {
                                text: chip.modelData.icon ?? "󰋙"
                                font.family: Theme.font.icon
                                font.pointSize: Theme.font.medium
                                color: chipMouse.containsMouse
                                    ? Theme.colors.bg : Theme.colors.accent
                            }
                            Text {
                                text: chip.modelData.name ?? ""
                                font.family: Theme.font.main
                                font.pointSize: Theme.font.small
                                color: chipMouse.containsMouse
                                    ? Theme.colors.bg : Theme.colors.textPrimary
                            }
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: picker.picked(chip.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
