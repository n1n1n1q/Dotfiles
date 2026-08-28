import QtQuick
import QtQuick.Layouts
import qs.config

// Small pill-shaped text button for inline actions (Connect / Cancel / Forget).
Rectangle {
    id: root

    property string text: ""
    property bool accent: false
    property bool danger: false
    property bool enabledButton: true
    signal clicked()

    implicitWidth: label.implicitWidth + Theme.spacing.medium * 2
    implicitHeight: 32
    radius: height / 2
    opacity: enabledButton ? 1 : 0.4

    color: !enabledButton ? Theme.colors.surfaceVariant
        : accent ? (mouse.containsMouse ? Theme.colors.accentAlt : Theme.colors.accent)
        : danger ? (mouse.containsMouse ? Theme.colors.error : Qt.rgba(Theme.colors.error.r, Theme.colors.error.g, Theme.colors.error.b, 0.15))
        : (mouse.containsMouse ? Theme.colors.surface : Theme.colors.surfaceVariant)

    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.family: Theme.font.main
        font.pointSize: Theme.font.small
        font.weight: Theme.font.semiBold
        color: root.accent ? Theme.colors.bg
            : root.danger ? (mouse.containsMouse ? Theme.colors.bg : Theme.colors.error)
            : Theme.colors.textPrimary
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
