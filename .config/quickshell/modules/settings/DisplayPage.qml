import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.settings

SettingsPage {
    heading: "Display"
    icon: "󰍹"
    blurb: "Monitors attached to this session."

    SettingsGroup {
        caption: "Monitors"
        icon: "󰍹"

        Repeater {
            model: Quickshell.screens

            delegate: SettingsRow {
                required property var modelData
                icon: "󰍹"
                title: modelData.name + (modelData.model ? "  ·  " + modelData.model : "")
                subtitle: modelData.width + "×" + modelData.height
                    + "  ·  scale " + (modelData.devicePixelRatio ?? 1).toFixed(2)
            }
        }
    }

    SettingsGroup {
        caption: "Options"
        icon: "󰒓"

        SettingsRow {
            icon: "󰕰"
            title: "Arrangement & scaling"
            subtitle: "Position, resolution, refresh rate and rotation"
            Text {
                text: "Soon"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
        }

        SettingsRow {
            icon: "󰖙"
            title: "Night light"
            subtitle: "Warm the colour temperature after dark"
            Text {
                text: "Soon"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
        }
    }
}
