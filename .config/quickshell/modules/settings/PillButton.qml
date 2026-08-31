import QtQuick
import QtQuick.Layouts
import qs.config

// Small pill-shaped button for inline actions (Connect / Reload / Forget).
// Sized to sit in a row's trailing slot without setting the row's height.
Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    property bool accent: false
    property bool danger: false
    property bool enabledButton: true
    signal clicked()

    implicitWidth: content.implicitWidth + Theme.spacing.normal * 2
    implicitHeight: 28
    radius: height / 2
    opacity: enabledButton ? 1 : 0.4

    color: !enabledButton ? Theme.colors.surfaceVariant
        : accent ? (mouse.containsMouse ? Theme.colors.accentAlt : Theme.colors.accent)
        : danger ? (mouse.containsMouse ? Theme.colors.error : Qt.rgba(Theme.colors.error.r, Theme.colors.error.g, Theme.colors.error.b, 0.15))
        : (mouse.containsMouse ? Theme.colors.surface : Theme.colors.surfaceVariant)

    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

    readonly property color _fg: accent ? Theme.colors.bg
        : danger ? (mouse.containsMouse ? Theme.colors.bg : Theme.colors.error)
        : Theme.colors.textPrimary

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Theme.spacing.tiny

        Text {
            visible: root.icon.length > 0
            text: root.icon
            font.family: Theme.font.icon
            font.pointSize: Theme.font.small
            color: root._fg
        }

        Text {
            visible: root.text.length > 0
            text: root.text
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            font.weight: Theme.font.mediumWeight
            color: root._fg
        }
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
