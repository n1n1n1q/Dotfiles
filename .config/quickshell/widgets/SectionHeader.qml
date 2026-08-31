import QtQuick
import QtQuick.Layouts
import qs.config

// The band that names a section: an accent glyph, the title, and an optional
// dim aside trailing it. SettingsGroup draws one above its card; pages drop it
// in directly when a section is built out of something other than a group.
RowLayout {
    id: root

    property string title: ""
    property string icon: ""
    property string hint: ""

    // Controls that belong to the section rather than to any one row — a count
    // pill, a "clear all", a mode switch.
    default property alias trailing: slot.data

    Layout.fillWidth: true
    Layout.leftMargin: Theme.spacing.small
    spacing: Theme.spacing.small

    Text {
        visible: root.icon.length > 0
        text: root.icon
        font.family: Theme.font.icon
        font.pointSize: Theme.font.medium
        color: Theme.colors.accent
    }

    Text {
        text: root.title
        font.family: Theme.font.main
        font.pointSize: Theme.font.large
        font.weight: Theme.font.mediumWeight
        color: Theme.colors.textPrimary
    }

    Text {
        Layout.fillWidth: true
        text: root.hint
        elide: Text.ElideRight
        font.family: Theme.font.main
        font.pointSize: Theme.font.small
        color: Theme.colors.textTertiary
    }

    RowLayout {
        id: slot
        Layout.alignment: Qt.AlignVCenter
        spacing: Theme.spacing.small
    }
}
