import QtQuick
import qs.config

// Small square icon button for inline row actions (move up/down, delete).
Rectangle {
    id: root

    property string icon: ""
    property bool danger: false
    property bool highlighted: false
    property bool enabledButton: true
    signal clicked()

    implicitWidth: 28
    implicitHeight: 28
    radius: Theme.rounding.small
    opacity: enabledButton ? 1 : 0.35
    color: !enabledButton ? "transparent"
        : mouse.containsMouse ? (danger
            ? Qt.rgba(Theme.colors.error.r, Theme.colors.error.g, Theme.colors.error.b, 0.18)
            : Theme.colors.surfaceVariant)
        : highlighted ? Theme.colors.surfaceVariant
        : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.family: Theme.font.icon
        font.pointSize: Theme.font.medium
        color: root.danger && mouse.containsMouse ? Theme.colors.error : Theme.colors.textSecondary
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabledButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
