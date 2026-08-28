import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services.niri
import qs.modules.settings

SettingsPage {
    heading: "niri"
    blurb: "The scrollable-tiling Wayland compositor this session runs on."

    SettingsGroup {
        SettingsRow {
            icon: "󱂬"
            title: "IPC bridge"
            subtitle: NiriService.available
                ? "Connected to $NIRI_SOCKET"
                : "Not connected"
            Text {
                text: NiriService.available ? "OK" : "—"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: NiriService.available ? Theme.colors.success : Theme.colors.textTertiary
            }
        }

        SettingsRow {
            icon: "󰍹"
            title: "Workspaces"
            subtitle: NiriService.workspaces.length + " across all outputs"
        }
    }

    SettingsGroup {
        caption: "Configuration"

        SettingsRow {
            icon: "󰅩"
            title: "Gaps, focus & animations"
            subtitle: "Edited directly in config.kdl for now"
            Text {
                text: "Soon"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
        }

        SettingsRow {
            icon: "󰑓"
            title: "Reload niri config"
            subtitle: "niri msg action load-config-file"
            Text {
                text: "Soon"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
        }
    }
}
