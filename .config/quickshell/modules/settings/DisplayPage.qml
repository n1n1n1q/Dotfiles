import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.display
import qs.modules.settings

SettingsPage {
    id: page
    heading: "Display"
    icon: "󰍹"
    blurb: "Monitors attached to this session."

    Component.onCompleted: NiriConfig.refreshOutputs()
    Connections {
        target: SettingsController
        function onSectionChanged() {
            if (SettingsController.section === "display")
                NiriConfig.refreshOutputs();
        }
    }

    readonly property var scaleOptions: ["1", "1.25", "1.5", "1.75", "2", "2.5", "3"]
    readonly property var transformOptions: ["normal", "90", "180", "270", "flipped", "flipped-90", "flipped-180", "flipped-270"]
    readonly property var vrrOptions: [
        { v: "off", l: "Off" }, { v: "on", l: "On" }, { v: "ondemand", l: "On demand" }
    ]

    // --- Windows-style mode switcher ---------------------------------
    SettingsGroup {
        visible: NiriConfig.outputsSplit
        caption: "Display mode"
        icon: "󰍺"
        hint: "also Mod+P · qs ipc call display menu"

        SettingsRow {
            icon: "󰍺"
            title: "Mode"
            subtitle: DisplayController.multiMonitor
                ? "Extend across both, or use just one"
                : "One display connected — plug in a second for Extend / external-only"
            SegmentedControl {
                value: DisplayController.currentMode
                options: [
                    { value: "internal", label: "PC screen" },
                    { value: "extend",   label: "Extend" },
                    { value: "external", label: "Second only" }
                ]
                onPicked: v => DisplayController.apply(v)
            }
        }
    }

    // --- setup prompt --------------------------------------------------
    SettingsGroup {
        visible: !NiriConfig.outputsSplit
        caption: "Config editing"
        icon: "󰈔"

        SettingsRow {
            icon: "󰩫"
            title: "Split out the output blocks"
            subtitle: "Moves every `output \"…\"` block from config.kdl into "
                + "~/.config/niri/quickshell/outputs.kdl (verbatim) and adds an "
                + "include, so the controls below can edit them. Backed up and validated."
            PillButton {
                text: NiriConfig.busy ? "Working…" : "Set up"
                accent: true
                enabledButton: !NiriConfig.busy
                onClicked: NiriConfig.runSplit()
            }
        }
    }

    // --- one group per monitor --------------------------------------
    Repeater {
        model: NiriConfig.outputsSplit ? NiriConfig.outputs : []

        delegate: SettingsGroup {
            id: mon
            required property var modelData
            readonly property var o: modelData

            // The combos fire `activated` while their model repopulates on
            // load — only act on real user picks, after this settles.
            property bool armed: false
            Component.onCompleted: Qt.callLater(() => mon.armed = true)

            caption: o.name + (o.model ? "  ·  " + o.model : "")
            icon: "󰍹"

            SettingsRow {
                compact: true
                icon: "󰐥"
                title: "Enabled"
                subtitle: o.connected ? "Connected" : "Not currently connected"
                SettingsToggle {
                    checked: !mon.o.off
                    busy: NiriConfig.busy
                    onToggled: v => {
                        if (v === mon.o.off)
                            NiriConfig.setOutput(mon.o.name, "enabled", v ? 1 : 0);
                    }
                }
            }

            SettingsRow {
                visible: !mon.o.off
                compact: true
                icon: "󰓅"
                title: "Variable refresh rate"
                SettingsCombo {
                    Layout.preferredWidth: 128
                    model: page.vrrOptions.map(x => x.l)
                    currentIndex: Math.max(0, page.vrrOptions.findIndex(x => x.v === mon.o.vrr))
                    onActivated: {
                        const want = page.vrrOptions[currentIndex].v;
                        if (mon.armed && want !== mon.o.vrr)
                            NiriConfig.setOutput(mon.o.name, "vrr", want);
                    }
                }
            }

            SettingsRow {
                visible: !mon.o.off
                icon: "󰍹"
                title: "Resolution & refresh"
                subtitle: mon.o.modes.length ? (mon.o.modes.length + " modes") : "no live mode list"
                SettingsCombo {
                    Layout.preferredWidth: 220
                    model: ["Auto"].concat(page._modeLabels(mon.o))
                    currentIndex: page._modeIndex(mon.o)
                    onActivated: {
                        if (!mon.armed) return;
                        const want = currentIndex === 0 ? "" : mon.o.modes[currentIndex - 1].value;
                        if (want !== mon.o.mode)
                            NiriConfig.setOutput(mon.o.name, "mode", want);
                    }
                }
            }

            SettingsRow {
                visible: !mon.o.off
                compact: true
                icon: "󰏘"
                title: "Scale"
                SettingsCombo {
                    Layout.preferredWidth: 92
                    model: page.scaleOptions
                    fallbackText: page._trimNum(mon.o.scale)
                    currentIndex: find(page._trimNum(mon.o.scale))
                    onActivated: {
                        if (mon.armed && currentText !== page._trimNum(mon.o.scale))
                            NiriConfig.setOutput(mon.o.name, "scale", currentText);
                    }
                }
            }

            SettingsRow {
                visible: !mon.o.off
                compact: true
                icon: "󰑵"
                title: "Rotation"
                SettingsCombo {
                    Layout.preferredWidth: 124
                    model: page.transformOptions
                    currentIndex: Math.max(0, find(mon.o.transform))
                    onActivated: {
                        if (mon.armed && currentText !== mon.o.transform)
                            NiriConfig.setOutput(mon.o.name, "transform", currentText);
                    }
                }
            }

        }
    }

    // --- helpers -----------------------------------------------------
    function _trimNum(n) {
        const s = (typeof n === "number") ? String(n) : String(parseFloat(n) || 1);
        return s;
    }
    function _modeLabels(o) {
        return o.modes.map(m => m.label + (m.preferred ? "  (preferred)" : ""));
    }
    function _modeIndex(o) {
        if (!o.mode) return 0;
        const res = o.mode.split("@")[0];
        const hz = parseFloat((o.mode.split("@")[1] ?? "0"));
        let i = o.modes.findIndex(m => m.value === o.mode);
        if (i < 0 && hz) {
            let best = -1, bestErr = 1;
            o.modes.forEach((m, k) => {
                if (m.value.split("@")[0] !== res) return;
                const e = Math.abs(parseFloat(m.value.split("@")[1]) - hz);
                if (e < bestErr) { bestErr = e; best = k; }
            });
            i = best;
        }
        if (i < 0) i = o.modes.findIndex(m => m.value.split("@")[0] === res);
        return i < 0 ? 0 : i + 1;
    }
}
