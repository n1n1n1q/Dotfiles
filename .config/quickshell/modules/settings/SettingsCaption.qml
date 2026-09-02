import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

// Small dim label naming a run of controls inside a section card — one step
// below a SettingsGroup caption.
RowLayout {
    id: root

    property string text: ""

    Layout.fillWidth: true
    Layout.topMargin: Theme.spacing.tiny
    Layout.leftMargin: Theme.spacing.small
    spacing: Theme.spacing.tiny

    Text {
        text: root.text
        font.family: Theme.font.main
        font.pointSize: Theme.font.small
        color: Theme.colors.textTertiary
    }

    Item { Layout.fillWidth: true }
}
