import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services.niri
import qs.modules.settings

SettingsPage {
    heading: "Keyboard"
    icon: "󰌌"
    blurb: "Layouts come from the niri config; the shell reflects the live state."

    SettingsGroup {
        caption: "Layouts"
        icon: "󰌌"

        Repeater {
            model: NiriService.keyboardLayoutNames

            delegate: SettingsRow {
                required property var modelData
                required property int index
                icon: index === NiriService.keyboardLayoutIdx ? "󰄬" : "󰧟"
                title: modelData
                subtitle: index === NiriService.keyboardLayoutIdx ? "Active" : ""
            }
        }
    }

    SettingsGroup {
        caption: "Options"
        icon: "󰒓"

        SettingsRow {
            icon: "󰌏"
            title: "Repeat rate & delay"
            subtitle: "Set in ~/.config/niri/config.kdl"
            Text {
                text: "Soon"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
        }

        SettingsRow {
            icon: "󰘳"
            title: "Shortcuts"
            subtitle: "Compositor keybinds"
            Text {
                text: "Soon"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
        }
    }
}
