import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings

SettingsPage {
    heading: "Widgets"
    blurb: "Individual bar and dashboard widgets."

    SettingsGroup {
        caption: "Style"

        SettingsRow {
            icon: "󰀉"
            title: "Circular gauge look"
            subtitle: "Theme.widget.circularStyle"
            Text {
                text: Theme.widget.circularStyle
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textSecondary
            }
        }
    }

    SettingsGroup {
        caption: "Catalogue"

        SettingsRow {
            icon: "󰐕"
            title: "Add / remove widgets"
            subtitle: "Pick which widgets appear and configure each one"
            Text {
                text: "Soon"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
        }
    }
}
