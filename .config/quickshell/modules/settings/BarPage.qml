import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings

SettingsPage {
    id: page
    heading: "Bar"
    blurb: "The top bar is groups of widgets in three regions. Toggle a group's "
        + "shared background, reorder with the arrows, add widgets from the "
        + "catalogue. Saved live to ~/.config/quickshell/bar.json."

    component SectionEditor: ColumnLayout {
        id: se
        required property string section
        required property string label
        required property var groups

        Layout.fillWidth: true
        spacing: Theme.spacing.small

        Text {
            text: se.label
            Layout.leftMargin: Theme.spacing.tiny
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            font.weight: Theme.font.semiBold
            font.capitalization: Font.AllUppercase
            color: Theme.colors.textTertiary
        }

        Repeater {
            model: se.groups
            delegate: BarGroupEditor {
                required property var modelData
                required property int index
                section: se.section
                groupIndex: index
                group: modelData
                groupCount: se.groups.length
            }
        }

        Text {
            visible: se.groups.length === 0
            text: "No groups in this region."
            Layout.leftMargin: Theme.spacing.tiny
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            color: Theme.colors.textTertiary
        }

        PillButton {
            text: "＋ Add group"
            onClicked: BarConfig.addGroup(se.section)
        }
    }

    SectionEditor { section: "left";   label: "Left";   groups: BarConfig.left }
    SectionEditor { section: "center"; label: "Centre"; groups: BarConfig.center }
    SectionEditor { section: "right";  label: "Right";  groups: BarConfig.right }

    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.colors.border }

    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: "Reset the layout to the shipped default."
            wrapMode: Text.WordWrap
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            color: Theme.colors.textTertiary
        }
        PillButton {
            text: "Reset to default"
            danger: true
            onClicked: BarConfig.reset()
        }
    }
}
