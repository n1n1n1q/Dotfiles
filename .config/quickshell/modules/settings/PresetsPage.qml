import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.modules.settings

SettingsPage {
    id: page
    heading: "Presets"
    icon: "󰏗"
    blurb: "Save the whole setup — colour scheme, fonts, wallpaper, avatar, bar "
        + "layout and desktop widgets — under a name, and switch back to it in "
        + "one click. Presets are JSON files in ~/.config/quickshell/presets/."

    function saveTyped() {
        const n = Presets.sanitize(nameField.text);
        if (n.length === 0)
            return;
        Presets.save(n);
        nameField.text = "";
        nameField.focus = false;
    }

    // --- save the current setup ------------------------------------------
    SettingsGroup {
        caption: "Save"
        icon: "󰆓"

        SettingsRow {
            icon: "󰆓"
            title: "Save current setup"
            subtitle: {
                const n = Presets.sanitize(nameField.text);
                if (n.length === 0)
                    return "Everything the shell persists, captured as one named preset";
                if (Presets.exists(n))
                    return "“" + n + "” already exists — saving replaces it";
                return "Saves as “" + n + "”";
            }

            Rectangle {
                Layout.preferredWidth: 200
                implicitHeight: 32
                radius: height / 2
                color: Theme.colors.surfaceVariant

                TextField {
                    id: nameField
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacing.normal
                    anchors.rightMargin: Theme.spacing.normal
                    verticalAlignment: Text.AlignVCenter
                    placeholderText: "Preset name"
                    color: Theme.colors.textPrimary
                    placeholderTextColor: Theme.colors.textTertiary
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.small
                    background: Item {}
                    onAccepted: page.saveTyped()
                }
            }

            PillButton {
                text: Presets.exists(nameField.text) ? "Overwrite" : "Save"
                accent: true
                enabledButton: Presets.sanitize(nameField.text).length > 0
                onClicked: page.saveTyped()
            }
        }

        // Applying replaces the entire setup, and what it replaced may never
        // have been saved anywhere — so there's always one step back.
        SettingsRow {
            visible: Presets.canUndo
            icon: "󰕌"
            title: "Undo apply"
            subtitle: "Put back the setup that was live before the last preset"
            PillButton {
                text: "Undo"
                onClicked: Presets.undo()
            }
        }

        SettingsRow {
            icon: "󰉋"
            title: "Preset files"
            subtitle: "~/.config/quickshell/presets/ — drop a .json in to install someone else's setup"
            PillButton {
                text: "Reload"
                onClicked: Presets.reload()
            }
        }
    }

    // --- the presets themselves ------------------------------------------
    Flow {
        Layout.fillWidth: true
        spacing: Theme.spacing.small
        visible: Presets.count > 0

        Repeater {
            model: Presets.names
            delegate: PresetCard {
                required property var modelData
                presetName: modelData
                body: Presets.presets[modelData] ?? ({})
            }
        }
    }

    SettingsPlaceholder {
        visible: Presets.count === 0
        icon: "󰏗"
        label: "No presets yet"
        hint: "Get the shell looking the way you want, then name it above and save."
    }

    SettingsRow {
        icon: "󰘳"
        title: "Switch from a keybind"
        subtitle: "qs ipc call preset apply <name> — also list, save, remove, undo"
    }
}
