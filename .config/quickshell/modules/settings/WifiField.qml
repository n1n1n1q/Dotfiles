import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

// Single-line text input styled like the settings search box. Used for the
// Wi-Fi password / username prompts.
Rectangle {
    id: root

    property string placeholder: ""
    property string icon: ""
    property bool secret: false
    property alias text: field.text
    signal accepted()

    Layout.fillWidth: true
    implicitHeight: 40
    radius: Theme.rounding.medium
    color: Theme.colors.bg
    border.width: field.activeFocus ? 1 : 0
    border.color: Theme.colors.accent

    function forceActiveFocus() {
        field.forceActiveFocus();
    }
    function clear() {
        field.clear();
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.normal
        anchors.rightMargin: Theme.spacing.small
        spacing: Theme.spacing.small

        Text {
            visible: root.icon.length > 0
            text: root.icon
            font.family: Theme.font.icon
            font.pointSize: Theme.font.medium
            color: Theme.colors.textTertiary
        }

        TextField {
            id: field
            Layout.fillWidth: true
            placeholderText: root.placeholder
            color: Theme.colors.textPrimary
            placeholderTextColor: Theme.colors.textTertiary
            font.family: Theme.font.main
            font.pointSize: Theme.font.medium
            background: Item {}
            echoMode: root.secret ? TextInput.Password : TextInput.Normal
            inputMethodHints: root.secret
                ? (Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText)
                : (Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText)
            onAccepted: root.accepted()
        }

        Text {
            visible: root.secret && field.text.length > 0
            text: field.echoMode === TextInput.Password ? "󰈈" : "󰈉"
            font.family: Theme.font.icon
            font.pointSize: Theme.font.medium
            color: reveal.containsMouse ? Theme.colors.textPrimary : Theme.colors.textTertiary

            MouseArea {
                id: reveal
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: field.echoMode = field.echoMode === TextInput.Password
                    ? TextInput.Normal : TextInput.Password
            }
        }
    }
}
