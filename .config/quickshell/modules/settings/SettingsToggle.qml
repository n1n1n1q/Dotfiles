import QtQuick
import qs.config

// Themed on/off switch. Drop it into a SettingsRow's trailing slot.
Rectangle {
    id: root

    property bool checked: false
    // Set true while an async backend catches up so the control reads as busy
    // rather than "did nothing".
    property bool busy: false
    signal toggled(bool checked)

    implicitWidth: 46
    implicitHeight: 26
    radius: height / 2
    color: checked ? Theme.colors.accent : Theme.colors.surfaceVariant
    opacity: busy ? 0.6 : 1

    Behavior on color {
        ColorAnimation { duration: Theme.animation.fast }
    }
    Behavior on opacity {
        NumberAnimation { duration: Theme.animation.fast }
    }

    Rectangle {
        id: knob
        width: 20
        height: 20
        radius: height / 2
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? Theme.colors.bg : Theme.colors.textSecondary

        Behavior on x {
            NumberAnimation { duration: Theme.animation.fast; easing.type: Easing.OutCubic }
        }
        Behavior on color {
            ColorAnimation { duration: Theme.animation.fast }
        }
    }

    // Controlled component: never mutate `checked` here (that would clobber the
    // caller's binding to backend state — the "stays on after edit mode ends"
    // bug). Just report the intent; the caller flips the source, which flows
    // back through `checked`.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
