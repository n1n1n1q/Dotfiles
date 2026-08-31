import QtQuick
import QtQuick.Layouts
import qs.config

// Grid of desktop-widget tiles. Click a tile to pick it up — it appears on the
// target display and follows the pointer until you click to drop it on the
// wallpaper (Esc cancels). (Native cross-window drag isn't routed to layer
// surfaces in niri, so this stands in for dragging a tile straight out.)
Flow {
    id: root

    property string targetScreen: ""

    spacing: Theme.spacing.small

    Repeater {
        model: DesktopConfig.catalogue

        delegate: Rectangle {
            id: tile
            required property var modelData

            implicitWidth: 132
            implicitHeight: 86
            radius: Theme.rounding.large
            color: ma.pressed ? Theme.colors.accent
                : ma.containsMouse ? Theme.colors.surfaceVariant
                : Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                          Theme.colors.surfaceVariant.b, 0.45)

            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: tile.modelData.icon
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.xlarge + 4
                    color: ma.pressed ? Theme.colors.bg : Theme.colors.accent
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: tile.modelData.name
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.small
                    font.weight: Theme.font.mediumWeight
                    color: ma.pressed ? Theme.colors.bg : Theme.colors.textPrimary
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "click to place"
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.tiny
                    color: ma.pressed ? Theme.colors.bg : Theme.colors.textTertiary
                }
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: DesktopConfig.placeNew(tile.modelData.type, root.targetScreen)
            }
        }
    }
}
