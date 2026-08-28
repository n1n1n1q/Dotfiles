import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings

// One colour-scheme option: a strip of swatches, the name, and a check when
// it's the active scheme. Tap to apply.
Rectangle {
    id: root

    required property string schemeName
    required property var colors
    property string blockPosition: "single"
    readonly property bool selected: Appearance.schemeName === schemeName

    readonly property int _r: Theme.workspace.indicatorRadius
    readonly property bool _rt: blockPosition === "top" || blockPosition === "single"
    readonly property bool _rb: blockPosition === "bottom" || blockPosition === "single"

    Layout.fillWidth: true
    implicitHeight: 56
    color: mouse.containsMouse ? Theme.colors.surfaceVariant : Theme.colors.surface
    topLeftRadius: _rt ? _r : 0
    topRightRadius: _rt ? _r : 0
    bottomLeftRadius: _rb ? _r : 0
    bottomRightRadius: _rb ? _r : 0

    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.normal
        anchors.rightMargin: Theme.spacing.normal
        spacing: Theme.spacing.normal

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 96
            implicitHeight: 30
            radius: Theme.rounding.small
            clip: true
            color: root.colors.base ?? "#000"
            border.width: 1
            border.color: Theme.colors.border

            Row {
                anchors.centerIn: parent
                spacing: 4
                Repeater {
                    model: [root.colors.surface1, root.colors.blue, root.colors.green,
                            root.colors.yellow, root.colors.red, root.colors.mauve]
                    delegate: Rectangle {
                        required property var modelData
                        width: 10
                        height: 18
                        radius: 3
                        color: modelData ?? "#888"
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.schemeName.charAt(0).toUpperCase() + root.schemeName.slice(1)
            font.family: Theme.font.main
            font.pointSize: Theme.font.medium
            font.weight: root.selected ? Theme.font.semiBold : Theme.font.mediumWeight
            color: Theme.colors.textPrimary
        }

        Text {
            visible: root.selected
            text: "󰄬"
            font.family: Theme.font.icon
            font.pointSize: Theme.font.large
            color: Theme.colors.accent
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
