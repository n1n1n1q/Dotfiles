import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.modules.settings

// A segmented block with an icon, label, live percentage, a mute toggle and a
// volume slider underneath. Used for output, input and per-app volume.
Rectangle {
    id: root

    property string icon: "󰕾"
    property string title: ""
    property string subtitle: ""
    property real value: 0
    property bool muted: false
    property string blockPosition: "single"
    property color accent: Theme.colors.accent
    signal moved(real v)
    signal muteToggled()

    readonly property int _r: Theme.workspace.indicatorRadius
    readonly property bool _rt: blockPosition === "top" || blockPosition === "single"
    readonly property bool _rb: blockPosition === "bottom" || blockPosition === "single"

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + Theme.spacing.normal * 2
    color: Theme.colors.surface
    topLeftRadius: _rt ? _r : 0
    topRightRadius: _rt ? _r : 0
    bottomLeftRadius: _rb ? _r : 0
    bottomRightRadius: _rb ? _r : 0

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacing.normal
        anchors.rightMargin: Theme.spacing.normal
        spacing: Theme.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.normal

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 34
                implicitHeight: 34
                radius: Theme.rounding.small
                color: mute.containsMouse ? Theme.colors.surfaceVariant
                    : root.muted ? Qt.rgba(Theme.colors.error.r, Theme.colors.error.g, Theme.colors.error.b, 0.18)
                    : Theme.colors.surfaceVariant

                Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                Text {
                    anchors.centerIn: parent
                    text: root.muted ? "󰝟" : root.icon
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.large
                    color: root.muted ? Theme.colors.error : Theme.colors.textPrimary
                }

                MouseArea {
                    id: mute
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.muteToggled()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: -1

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    elide: Text.ElideRight
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.medium
                    font.weight: Theme.font.mediumWeight
                    color: Theme.colors.textPrimary
                }
                Text {
                    visible: root.subtitle.length > 0
                    Layout.fillWidth: true
                    text: root.subtitle
                    elide: Text.ElideRight
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.small
                    color: Theme.colors.textTertiary
                }
            }

            Text {
                text: Math.round(root.value * 100) + "%"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                font.weight: Theme.font.semiBold
                font.features: ({ "tnum": 1 })
                color: root.muted ? Theme.colors.textTertiary : Theme.colors.textSecondary
            }
        }

        Slider {
            id: slider
            Layout.fillWidth: true
            Layout.leftMargin: 34 + Theme.spacing.normal
            from: 0
            to: 1
            value: root.value
            opacity: root.muted ? 0.5 : 1
            onMoved: root.moved(value)

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 4
                radius: 2
                color: Theme.colors.surfaceVariant
                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: root.accent
                }
            }
            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: 16
                height: 16
                radius: 8
                color: slider.pressed ? Theme.colors.accentAlt : Theme.colors.textPrimary
            }
        }
    }
}
