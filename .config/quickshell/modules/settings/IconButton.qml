import QtQuick
import QtQuick.Controls
import qs.config

// Small icon-only button for inline row actions (move up/down, delete) and for
// the window furniture in the title bar.
Rectangle {
    id: root

    property string icon: ""
    property bool danger: false
    property bool highlighted: false
    property bool enabledButton: true
    property bool round: false
    property string tooltip: ""
    property int size: 28
    signal clicked()

    implicitWidth: size
    implicitHeight: size
    radius: round ? height / 2 : Theme.rounding.small
    opacity: enabledButton ? 1 : 0.35
    color: !enabledButton ? "transparent"
        : mouse.containsMouse ? (danger
            ? Qt.rgba(Theme.colors.error.r, Theme.colors.error.g, Theme.colors.error.b, 0.18)
            : Theme.colors.surfaceVariant)
        : highlighted ? Theme.colors.surfaceVariant
        : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

    // `tooltip` is kept as an inert compat prop — Settings no longer shows
    // tooltips (the user found them more distracting than useful there).

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
