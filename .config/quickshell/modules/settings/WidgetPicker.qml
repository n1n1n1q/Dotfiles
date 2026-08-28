import QtQuick
import QtQuick.Layouts
import qs.config

// Inline list of every catalogue widget; emits `picked(id)` on tap.
ColumnLayout {
    id: root

    signal picked(string id)

    Layout.fillWidth: true
    spacing: 2

    Repeater {
        model: BarConfig.catalogue

        delegate: Rectangle {
            id: row
            required property var modelData

            Layout.fillWidth: true
            implicitHeight: 46
            radius: Theme.rounding.small
            color: ma.containsMouse ? Theme.colors.surfaceVariant : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing.normal
                anchors.rightMargin: Theme.spacing.normal
                spacing: Theme.spacing.normal

                Text {
                    text: row.modelData.icon
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.large
                    color: Theme.colors.textSecondary
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: -2
                    Text {
                        text: row.modelData.name
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.small
                        font.weight: Theme.font.mediumWeight
                        color: Theme.colors.textPrimary
                    }
                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.desc
                        elide: Text.ElideRight
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.tiny + 1
                        color: Theme.colors.textTertiary
                    }
                }
                Text {
                    text: "󰐕"
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.medium
                    color: Theme.colors.accent
                }
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(row.modelData.id)
            }
        }
    }
}
