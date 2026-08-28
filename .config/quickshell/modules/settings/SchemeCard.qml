import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings

// One colour-scheme tile in the General page's scheme grid: a swatch preview,
// the name, and a check when active. Tap to apply live.
Rectangle {
    id: root

    required property string schemeName
    required property var colors
    readonly property bool selected: Appearance.schemeName === schemeName

    implicitWidth: 152
    implicitHeight: 78
    radius: Theme.rounding.medium
    color: mouse.containsMouse ? Theme.colors.surfaceVariant : Theme.colors.surface
    border.width: selected ? 2 : 1
    border.color: selected ? Theme.colors.accent : Theme.colors.border
    clip: true

    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animation.fast } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.small
        spacing: Theme.spacing.tiny

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: Theme.rounding.small
            color: root.colors.base ?? "#000000"
            border.width: 1
            border.color: Theme.colors.border

            Row {
                anchors.centerIn: parent
                spacing: 4
                Repeater {
                    model: [root.colors.red, root.colors.peach, root.colors.green,
                            root.colors.blue, root.colors.mauve]
                    delegate: Rectangle {
                        required property var modelData
                        width: 13
                        height: 13
                        radius: 4
                        color: modelData ?? "#888888"
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.tiny

            Text {
                Layout.fillWidth: true
                text: root.schemeName.charAt(0).toUpperCase() + root.schemeName.slice(1)
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                font.weight: root.selected ? Theme.font.semiBold : Theme.font.mediumWeight
                color: Theme.colors.textPrimary
            }

            Text {
                visible: root.selected
                text: "󰄬"
                font.family: Theme.font.icon
                font.pointSize: Theme.font.medium
                color: Theme.colors.accent
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Appearance.setScheme(root.schemeName)
    }
}
