import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings

SettingsPage {
    heading: "Dashboard"
    blurb: "The panel that drops down from the window title on the left of the bar."

    SettingsGroup {
        caption: "Sections"

        Repeater {
            model: [
                { icon: "󰔎", title: "Quick toggles" },
                { icon: "󰕾", title: "Sliders" },
                { icon: "󰝚", title: "Media player" },
                { icon: "󰎟", title: "Notification centre" }
            ]
            delegate: SettingsRow {
                required property var modelData
                icon: modelData.icon
                title: modelData.title
                subtitle: "Shown"
                Text {
                    text: "Soon"
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.small
                    color: Theme.colors.textTertiary
                }
            }
        }
    }

    SettingsPlaceholder {
        icon: "󰕮"
        label: "Reorder & toggle sections"
        hint: "Choose which sections show and in what order."
    }
}
