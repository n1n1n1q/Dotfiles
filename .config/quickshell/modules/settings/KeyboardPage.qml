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

    // Shown until the niri `input` block is split into an includable fragment
    // (Settings › niri › "Split out the input block").
    SettingsGroup {
        visible: !NiriConfig.inputSplit
        caption: "Key repeat"
        icon: "󰌏"

        SettingsRow {
            icon: "󰌏"
            title: "Repeat rate & delay"
            subtitle: "Enable niri config editing on the niri page to adjust these"
            Text {
                text: "Set up"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
        }
    }

    SettingsGroup {
        visible: NiriConfig.inputSplit
        caption: "Key repeat"
        icon: "󰌏"

        SettingsRow {
            compact: true
            icon: "󰅐"
            title: "Delay"
            subtitle: "Before a held key repeats, ms"
            SettingsSpin {
                from: 100
                to: 2000
                step: 50
                suffix: " ms"
                value: NiriConfig.kbRepeatDelay
                onStepped: v => NiriConfig.setInput("keyboard.repeat-delay", v)
            }
        }
        SettingsRow {
            compact: true
            icon: "󰓅"
            title: "Rate"
            subtitle: "Repeats per second"
            SettingsSpin {
                from: 1
                to: 100
                step: 5
                value: NiriConfig.kbRepeatRate
                onStepped: v => NiriConfig.setInput("keyboard.repeat-rate", v)
            }
        }
    }
}
