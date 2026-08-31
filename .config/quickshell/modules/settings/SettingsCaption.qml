import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

// Small dim label naming a run of controls inside a section card — one step
// below a SettingsGroup caption. `hint` hangs an info glyph off the end that
// explains the run on hover.
RowLayout {
    id: root

    property string text: ""
    property string hint: ""

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

    Text {
        visible: root.hint.length > 0
        text: "󰋽"
        font.family: Theme.font.icon
        font.pointSize: Theme.font.small
        color: Theme.colors.textTertiary
        opacity: 0.7

        ToolTip.visible: hintHover.hovered
        ToolTip.text: root.hint
        ToolTip.delay: 300
        HoverHandler { id: hintHover }
    }

    Item { Layout.fillWidth: true }
}
