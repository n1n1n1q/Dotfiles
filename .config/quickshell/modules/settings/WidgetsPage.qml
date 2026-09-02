import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.settings

// Desktop widgets — one on/off switch per type. Flip one on and it drops onto
// every display near the centre of the primary output; turn on Edit layout to
// drag it where you want. Saved to ~/.config/quickshell/desktop.json.
SettingsPage {
    id: page
    heading: "Widgets"
    icon: "󰀻"
    blurb: "Widgets on the desktop wallpaper. Switch one on, then use Edit "
        + "layout to drag it into place."

    // "All displays" + every connected output.
    readonly property var screenOptions: {
        let n = ["all"];
        for (const s of Quickshell.screens) n.push(s.name);
        return n;
    }
    function screenLabel(v) { return v === "all" ? "All displays" : v; }

    // --- edit mode ------------------------------------------------------
    SettingsGroup {
        caption: "Editing"
        icon: "󰙭"

        SettingsRow {
            icon: "󰙭"
            title: "Edit layout"
            subtitle: "Drag to move, drag a corner to resize, hold Shift to snap. "
                + "Enter saves · Esc cancels · switching workspace cancels."
            SettingsToggle {
                checked: DesktopConfig.editMode
                onToggled: v => v ? DesktopConfig.beginEdit() : DesktopConfig.commitEdit()
            }
        }
    }

    // --- one group per widget type -----------------------------------
    Repeater {
        model: DesktopConfig.catalogue

        delegate: SettingsGroup {
            id: grp
            required property var modelData
            readonly property string type: modelData.type
            readonly property bool on: DesktopConfig.hasType(type)
            readonly property var p: (DesktopConfig.firstOfType(type)?.props)
                ?? DesktopConfig.defaultsFor(type)

            // The combos below fire `activated` while their model repopulates
            // on load — only act on real user picks, after this settles.
            property bool armed: false
            Component.onCompleted: Qt.callLater(() => grp.armed = true)

            caption: modelData.name
            icon: modelData.icon
            // Toggles pair two-up; the ones with a combo / picker stay full.
            dense: true

            SettingsRow {
                wide: true
                icon: grp.modelData.icon
                title: "Show on desktop"
                subtitle: grp.modelData.desc
                SettingsToggle {
                    checked: grp.on
                    onToggled: v => v ? DesktopConfig.enableType(grp.type)
                                      : DesktopConfig.removeType(grp.type)
                }
            }

            SettingsRow {
                visible: grp.on
                wide: true
                icon: "󰍹"
                title: "Display"
                subtitle: (DesktopConfig.firstOfType(grp.type)?.screen ?? "all") === "all"
                    ? "On every screen — Edit layout lets you place it separately on each"
                    : "Only on this output"
                SettingsCombo {
                    Layout.preferredWidth: 180
                    model: page.screenOptions
                    displayText: page.screenLabel(currentText)
                    Component.onCompleted: currentIndex = Math.max(0,
                        page.screenOptions.indexOf(DesktopConfig.firstOfType(grp.type)?.screen ?? "all"))
                    onActivated: {
                        if (grp.armed)
                            DesktopConfig.setScreenForType(grp.type, currentText);
                    }
                }
            }

            SettingsRow {
                visible: grp.on
                icon: "󰉉"
                title: "Size"
                SettingsSpin {
                    readonly property string key: grp.type === "clock" ? "fontScale" : "scale"
                    from: 50
                    to: 250
                    step: 10
                    suffix: "%"
                    value: Math.round((grp.p[key] ?? 1.0) * 100)
                    onStepped: v => DesktopConfig.setPropForType(grp.type, key, v / 100)
                }
            }

            // --- clock -------------------------------------------------
            SettingsRow {
                visible: grp.on && grp.type === "clock"
                icon: "󰅐"
                title: "24-hour clock"
                SettingsToggle {
                    checked: grp.p.format24 ?? true
                    onToggled: v => DesktopConfig.setPropForType("clock", "format24", v)
                }
            }
            SettingsRow {
                visible: grp.on && grp.type === "clock"
                icon: "󰃭"
                title: "Show the date"
                SettingsToggle {
                    checked: grp.p.showDate ?? true
                    onToggled: v => DesktopConfig.setPropForType("clock", "showDate", v)
                }
            }
            SettingsRow {
                visible: grp.on && grp.type === "clock"
                icon: "󰉢"
                title: "Alignment"
                SettingsCombo {
                    Layout.preferredWidth: 140
                    model: ["Left", "Center", "Right"]
                    Component.onCompleted: currentIndex = ["left", "center", "right"]
                        .indexOf(grp.p.align ?? "center")
                    onActivated: {
                        if (grp.armed)
                            DesktopConfig.setPropForType("clock", "align", currentText.toLowerCase());
                    }
                }
            }

            // --- stats -----------------------------------------------
            SettingsRow {
                visible: grp.on && grp.type === "stats"
                icon: "󰻠"
                title: "CPU gauge"
                SettingsToggle {
                    checked: grp.p.showCpu ?? true
                    onToggled: v => DesktopConfig.setPropForType("stats", "showCpu", v)
                }
            }
            SettingsRow {
                visible: grp.on && grp.type === "stats"
                icon: "󰍛"
                title: "RAM gauge"
                SettingsToggle {
                    checked: grp.p.showRam ?? true
                    onToggled: v => DesktopConfig.setPropForType("stats", "showRam", v)
                }
            }
            SettingsRow {
                visible: grp.on && grp.type === "stats"
                icon: "󰢮"
                title: "GPU gauge"
                SettingsToggle {
                    checked: grp.p.showGpu ?? false
                    onToggled: v => DesktopConfig.setPropForType("stats", "showGpu", v)
                }
            }

            // --- media -----------------------------------------------
            SettingsRow {
                visible: grp.on && grp.type === "media"
                wide: true
                icon: "󰝚"
                title: "Layout"
                MediaLayoutPicker {
                    labels: false
                    value: grp.p.layout ?? "regular"
                    onPicked: v => DesktopConfig.setPropForType("media", "layout", v)
                }
            }
        }
    }
}
