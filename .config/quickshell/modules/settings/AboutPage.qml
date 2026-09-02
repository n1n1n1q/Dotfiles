import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.services.niri
import qs.modules.settings

SettingsPage {
    heading: "About"
    icon: "󰋽"
    blurb: "The shell, the machine and the people behind it."

    SettingsGroup {
        caption: "Shell"
        icon: "󰆍"

        SettingsRow {
            compact: true
            icon: "󰆍"
            title: "Quickshell"
            subtitle: "Desktop shell runtime"
            Text {
                text: "0.3.1"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textSecondary
            }
        }

        SettingsRow {
            compact: true
            icon: "󱂬"
            title: "Compositor"
            subtitle: "niri · scrollable-tiling Wayland"
            Text {
                text: NiriService.available ? "connected" : "—"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textSecondary
            }
        }

        SettingsRow {
            icon: "󰉋"
            title: "Config"
            subtitle: Quickshell.env("HOME") + "/Dotfiles/.config/quickshell"
        }
    }

    SettingsGroup {
        caption: "This machine"
        icon: "󰍹"

        SettingsRow {
            compact: true
            icon: "󰀄"
            title: "User"
            Text {
                text: System.userName
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textSecondary
            }
        }

        SettingsRow {
            compact: true
            icon: "󰍹"
            title: "Outputs"
            Text {
                text: {
                    let names = [];
                    for (const s of Quickshell.screens)
                        names.push(s.name);
                    return names.join(", ");
                }
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textSecondary
            }
        }

        SettingsRow {
            icon: Battery.isLaptopBattery ? "󰁹" : "󰚥"
            title: "Power"
            subtitle: Battery.isLaptopBattery
                ? (Math.round(Battery.percentage * 100) + "%  ·  "
                   + (Battery.charging ? "charging"
                      : Battery.percentage >= 0.97 ? "full" : "on battery"))
                : "AC only"
        }
    }

    SettingsGroup {
        caption: "Credits"
        icon: "󰋼"

        SettingsRow {
            icon: "󰊤"
            title: "Dotfiles"
            subtitle: "Personal Arch + niri + Quickshell rice"
        }

        SettingsRow {
            icon: "󰋼"
            title: "Design cues"
            subtitle: "end-4's dots-hyprland, caelestia · Catppuccin Mocha"
        }
    }
}
