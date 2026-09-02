import QtQuick
import QtQuick.Layouts
import qs.config

// "− value +" stepper for a numeric setting. Round step buttons either side of
// the live value, sized to sit in a SettingsRow's trailing slot.
RowLayout {
    id: root

    property int value: 0
    property int from: 0
    property int to: 100
    property int step: 1
    property string suffix: ""
    signal stepped(int value)

    spacing: Theme.spacing.tiny

    component Step: Rectangle {
        id: btn
        property string glyph: ""
        property bool canPress: true
        signal act()

        implicitWidth: 26
        implicitHeight: 26
        radius: height / 2
        opacity: canPress ? 1 : 0.3
        color: btnMouse.containsMouse && canPress ? Theme.colors.accent
                                                  : Theme.palette.surface2

        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            font.family: Theme.font.icon
            font.pointSize: Theme.font.medium
            color: btnMouse.containsMouse && btn.canPress ? Theme.colors.bg
                                                          : Theme.colors.textSecondary
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            enabled: btn.canPress
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.act()
        }
    }

    Step {
        glyph: "󰍴"
        canPress: root.value > root.from
        onAct: root.stepped(Math.max(root.from, root.value - root.step))
    }

    Text {
        Layout.minimumWidth: 46
        horizontalAlignment: Text.AlignHCenter
        text: root.value + root.suffix
        font.family: Theme.font.main
        font.pointSize: Theme.font.medium
        color: Theme.colors.textPrimary
    }

    Step {
        glyph: "󰐕"
        canPress: root.value < root.to
        onAct: root.stepped(Math.min(root.to, root.value + root.step))
    }
}
