import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services.niri
import qs.modules.settings

SettingsPage {
    heading: "niri"
    icon: "󱂬"
    blurb: "The scrollable-tiling Wayland compositor this session runs on."

    SettingsGroup {
        caption: "Compositor"
        icon: "󱂬"

        SettingsRow {
            compact: true
            icon: "󱂬"
            title: "IPC bridge"
            Text {
                text: NiriService.available ? "OK" : "—"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: NiriService.available ? Theme.colors.success : Theme.colors.textTertiary
            }
        }
        SettingsRow {
            compact: true
            icon: "󰍹"
            title: "Workspaces"
            Text {
                text: NiriService.workspaces.length
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textSecondary
            }
        }

        SettingsRow {
            icon: "󰑓"
            title: "Reload config"
            subtitle: "niri msg action load-config-file"
            PillButton {
                text: "Reload"
                onClicked: NiriConfig.reloadNiri()
            }
        }
    }

    // --- setup prompt, shown until the layout / animations / input blocks
    //     are split out of config.kdl into includable fragments -------------
    SettingsGroup {
        visible: !NiriConfig.split || !NiriConfig.inputSplit
        caption: "Config editing"
        icon: "󰈔"

        SettingsRow {
            icon: "󰩫"
            title: NiriConfig.split ? "Split out the input block" : "Split out layout, animations & input"
            subtitle: "Moves those blocks from config.kdl into "
                + "~/.config/niri/quickshell/*.kdl (verbatim) and adds an include, "
                + "so the options below can edit them. A backup is kept and the "
                + "result is validated."
            PillButton {
                text: NiriConfig.busy ? "Working…" : (NiriConfig.split ? "Update" : "Set up")
                accent: true
                enabledButton: !NiriConfig.busy
                onClicked: NiriConfig.runSplit()
            }
        }
    }

    // --- live options, once split --------------------------------------
    SettingsGroup {
        visible: NiriConfig.split
        caption: "Layout"
        icon: "󰍹"

        SettingsRow {
            icon: "󰩨"
            title: "Gaps"
            subtitle: "Space around windows, logical px"
            SettingsSpin {
                from: 0
                to: 64
                step: 2
                value: NiriConfig.gaps
                onStepped: v => NiriConfig.set("layout.kdl", "gaps", v)
            }
        }

        SettingsRow {
            compact: true
            icon: "󰻂"
            title: "Focus ring"
            SettingsToggle {
                checked: NiriConfig.focusRing
                busy: NiriConfig.busy
                onToggled: v => NiriConfig.set("layout.kdl", "focus-ring.enabled", v ? 1 : 0)
            }
        }
        SettingsRow {
            compact: true
            icon: "󰅩"
            title: "Border"
            SettingsToggle {
                checked: NiriConfig.border
                busy: NiriConfig.busy
                onToggled: v => NiriConfig.set("layout.kdl", "border.enabled", v ? 1 : 0)
            }
        }

        SettingsRow {
            compact: true
            visible: NiriConfig.focusRing
            icon: "󰺫"
            title: "Ring width"
            SettingsSpin {
                from: 1
                to: 12
                value: NiriConfig.focusRingWidth
                onStepped: v => NiriConfig.set("layout.kdl", "focus-ring.width", v)
            }
        }
        SettingsRow {
            compact: true
            visible: NiriConfig.border
            icon: "󰺫"
            title: "Border width"
            SettingsSpin {
                from: 1
                to: 12
                value: NiriConfig.borderWidth
                onStepped: v => NiriConfig.set("layout.kdl", "border.width", v)
            }
        }
    }

    // --- pointer / input, once the input block is split ------------------
    SettingsGroup {
        visible: NiriConfig.inputSplit
        caption: "Pointer"
        icon: "󰦋"

        SettingsRow {
            compact: true
            icon: "󰦋"
            title: "Focus follows mouse"
            SettingsToggle {
                checked: NiriConfig.focusFollowsMouse
                busy: NiriConfig.busy
                onToggled: v => NiriConfig.setInput("focus-follows-mouse", v ? 1 : 0)
            }
        }
        SettingsRow {
            compact: true
            icon: "󰆾"
            title: "Warp mouse to focus"
            SettingsToggle {
                checked: NiriConfig.warpMouseToFocus
                busy: NiriConfig.busy
                onToggled: v => NiriConfig.setInput("warp-mouse-to-focus", v ? 1 : 0)
            }
        }
    }

    SettingsGroup {
        visible: NiriConfig.inputSplit
        caption: "Touchpad"
        icon: "󰟸"

        SettingsRow {
            compact: true
            icon: "󰤿"
            title: "Tap to click"
            SettingsToggle {
                checked: NiriConfig.tpTap
                busy: NiriConfig.busy
                onToggled: v => NiriConfig.setInput("touchpad.tap", v ? 1 : 0)
            }
        }
        SettingsRow {
            compact: true
            icon: "󰦍"
            title: "Natural scroll"
            SettingsToggle {
                checked: NiriConfig.tpNaturalScroll
                busy: NiriConfig.busy
                onToggled: v => NiriConfig.setInput("touchpad.natural-scroll", v ? 1 : 0)
            }
        }
        SettingsRow {
            compact: true
            icon: "󰌌"
            title: "Disable while typing"
            SettingsToggle {
                checked: NiriConfig.tpDwt
                busy: NiriConfig.busy
                onToggled: v => NiriConfig.setInput("touchpad.dwt", v ? 1 : 0)
            }
        }
        SettingsRow {
            compact: true
            icon: "󰓅"
            title: "Acceleration"
            subtitle: "libinput accel-speed, −100 to 100%"
            SettingsSpin {
                from: -100
                to: 100
                step: 10
                suffix: "%"
                value: Math.round(NiriConfig.tpAccel * 100)
                onStepped: v => NiriConfig.setInput("touchpad.accel-speed",
                    v === 0 ? "" : (v / 100).toFixed(2))
            }
        }
    }

    SettingsGroup {
        visible: NiriConfig.inputSplit
        caption: "Mouse"
        icon: "󰍽"

        SettingsRow {
            compact: true
            icon: "󰦍"
            title: "Natural scroll"
            SettingsToggle {
                checked: NiriConfig.mouseNaturalScroll
                busy: NiriConfig.busy
                onToggled: v => NiriConfig.setInput("mouse.natural-scroll", v ? 1 : 0)
            }
        }
        SettingsRow {
            compact: true
            icon: "󰓅"
            title: "Acceleration"
            subtitle: "libinput accel-speed, −100 to 100%"
            SettingsSpin {
                from: -100
                to: 100
                step: 10
                suffix: "%"
                value: Math.round(NiriConfig.mouseAccel * 100)
                onStepped: v => NiriConfig.setInput("mouse.accel-speed",
                    v === 0 ? "" : (v / 100).toFixed(2))
            }
        }
    }

    SettingsGroup {
        visible: NiriConfig.split
        caption: "Animations"
        icon: "󰎈"

        SettingsRow {
            compact: true
            icon: "󰐊"
            title: "Animations"
            SettingsToggle {
                checked: NiriConfig.animations
                busy: NiriConfig.busy
                onToggled: v => NiriConfig.set("animations.kdl", "animations.enabled", v ? 1 : 0)
            }
        }
        SettingsRow {
            compact: true
            visible: NiriConfig.animations
            icon: "󰾆"
            title: "Slowdown"
            SettingsSpin {
                from: 1
                to: 5
                value: Math.max(1, Math.round(NiriConfig.animationSlowdown))
                onStepped: v => NiriConfig.set("animations.kdl", "animations.slowdown", v === 1 ? 0 : v)
            }
        }
    }
}
