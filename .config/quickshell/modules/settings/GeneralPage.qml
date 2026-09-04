import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import qs.config
import qs.services
import qs.modules.settings
import qs.widgets

// Everything that decides how the shell looks, in the order you'd set a fresh
// machine up: who you are, the palette, the picture behind it, the type.
// Behaviour of individual surfaces lives on their own pages — the bar's frame
// on Bar, the OSD pill on Notifications.
SettingsPage {
    id: page
    heading: "General"
    icon: "󰏘"
    blurb: "Profile, colour scheme, wallpaper, fonts — and presets that save the "
        + "whole lot under a name. Schemes live in ~/.config/quickshell/colorschemes/, "
        + "wallpapers in ~/.config/quickshell/wallpapers/, presets in "
        + "~/.config/quickshell/presets/."

    // rescan the wallpapers folder whenever the settings window opens or the
    // user navigates here, so images added outside the shell show up
    Connections {
        target: SettingsController
        function onOpenChanged() { if (SettingsController.open) Wallpaper.reload(); }
        function onSectionChanged() { if (SettingsController.section === "general") Wallpaper.reload(); }
    }

    function saveTypedPreset() {
        const n = Presets.sanitize(presetNameField.text);
        if (n.length === 0)
            return;
        Presets.save(n);
        presetNameField.text = "";
        presetNameField.focus = false;
    }

    // --- profile ---------------------------------------------------------
    SettingsGroup {
        caption: "Profile"
        icon: "󰀄"
        hint: System.userName

        SettingsRow {
            icon: "󰗋"
            title: "Profile picture"
            subtitle: Appearance.avatar.length > 0 ? Appearance.avatar : "Not set — a placeholder is shown"

            // avatar preview
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 36
                implicitHeight: 36
                radius: height / 2
                color: Theme.colors.surfaceVariant
                clip: true

                Image {
                    anchors.fill: parent
                    source: Appearance.avatar.length > 0 ? ("file://" + Appearance.avatar) : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    sourceSize.width: 96
                    sourceSize.height: 96
                    cache: false
                }
                Text {
                    anchors.centerIn: parent
                    visible: Appearance.avatar.length === 0
                    text: "󰀄"
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.large
                    color: Theme.colors.textTertiary
                }
            }

            PillButton {
                text: "Change"
                onClicked: avatarDialog.open()
            }
            PillButton {
                visible: Appearance.avatar.length > 0
                text: "Remove"
                danger: true
                onClicked: Appearance.setAvatar("")
            }
        }

        SettingsRow {
            icon: "󰀄"
            title: "User"
            subtitle: System.userName
        }
    }

    FileDialog {
        id: avatarDialog
        title: "Choose a profile picture"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.gif *.bmp)"]
        onAccepted: {
            const p = selectedFile.toString().replace(/^file:\/\//, "");
            Appearance.setAvatar(decodeURIComponent(p));
        }
    }

    // --- colour scheme ---------------------------------------------------
    SettingsGroup {
        caption: "Colour scheme"
        icon: "󰏘"
        hint: Appearance.schemeName

        Flow {
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.tiny
            spacing: Theme.spacing.small

            Repeater {
                model: Appearance.schemeNames
                delegate: SchemeCard {
                    required property var modelData
                    schemeName: modelData
                    colors: Appearance.schemes[modelData] ?? ({})
                }
            }
        }

        SettingsRow {
            icon: "󰏘"
            title: "Cycle schemes"
            subtitle: "Super+Shift+T / Super+Ctrl+Shift+T — steps this list without opening Settings"
            PillButton {
                text: "Previous"
                onClicked: Appearance.cycleScheme(-1)
            }
            PillButton {
                text: "Next"
                accent: true
                onClicked: Appearance.cycleScheme(1)
            }
        }

        SettingsRow {
            icon: "󰉋"
            title: "Scheme files"
            subtitle: "~/.config/quickshell/colorschemes/ — add a .json to define your own"
            PillButton {
                text: "Reload"
                onClicked: Appearance.reloadSchemes()
            }
        }
    }

    // --- wallpaper -------------------------------------------------------
    SettingsGroup {
        caption: "Wallpaper"
        icon: "󰸉"
        hint: Wallpaper.wallpapers.length + (Wallpaper.wallpapers.length === 1 ? " image" : " images")

        SettingsRow {
            icon: "󰸉"
            title: "Wallpapers folder"
            subtitle: "~/.config/quickshell/wallpapers/ — applied with awww"
            PillButton {
                text: "Add…"
                accent: true
                onClicked: wallpaperDialog.open()
            }
            PillButton {
                text: "Reload"
                onClicked: Wallpaper.reload()
            }
        }

        // thumbnail grid
        Flow {
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.tiny
            spacing: Theme.spacing.small
            visible: Wallpaper.wallpapers.length > 0

            Repeater {
                model: Wallpaper.wallpapers
                delegate: Rectangle {
                    id: thumb
                    required property var modelData
                    readonly property bool selected: Wallpaper.current === modelData

                    width: 132
                    height: 76
                    radius: Theme.rounding.small
                    color: Theme.colors.surfaceVariant
                    border.width: selected ? 2 : 0
                    border.color: Theme.colors.accent
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: thumb.selected ? 2 : 0
                        source: "file://" + thumb.modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        sourceSize.width: 264
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 4
                        visible: thumbMouse.containsMouse
                        text: "󰅖"
                        font.family: Theme.font.icon
                        font.pointSize: Theme.font.normal
                        color: "white"
                        style: Text.Outline
                        styleColor: "#000000"

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            onClicked: Wallpaper.remove(thumb.modelData)
                        }
                    }

                    MouseArea {
                        id: thumbMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Wallpaper.select(thumb.modelData)
                    }
                }
            }
        }

        SettingsRow {
            icon: "󰑙"
            title: "Cycle wallpapers"
            subtitle: "Super+Shift+W / Super+Ctrl+Shift+W, Super+Alt+W to shuffle"
            PillButton {
                text: "Previous"
                enabledButton: Wallpaper.wallpapers.length > 0
                onClicked: Wallpaper.previous()
            }
            PillButton {
                text: "Next"
                accent: true
                enabledButton: Wallpaper.wallpapers.length > 0
                onClicked: Wallpaper.next()
            }
            PillButton {
                text: "Shuffle"
                enabledButton: Wallpaper.wallpapers.length > 1
                onClicked: Wallpaper.random()
            }
        }

        SettingsRow {
            visible: Wallpaper.wallpapers.length === 0
            icon: "󰋩"
            title: "No wallpapers yet"
            subtitle: "Use “Add…”, or drop images into the folder and hit Reload"
        }
    }

    FileDialog {
        id: wallpaperDialog
        title: "Add a wallpaper"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.gif *.bmp)"]
        onAccepted: {
            const p = selectedFile.toString().replace(/^file:\/\//, "");
            Wallpaper.addFromFile(decodeURIComponent(p));
        }
    }

    // --- fonts -----------------------------------------------------------
    SettingsGroup {
        caption: "Fonts"
        icon: "󰛖"

        component FontPick: SettingsRow {
            id: fp
            property string current: ""
            signal chosen(string family)

            SettingsCombo {
                Layout.preferredWidth: 220
                model: Qt.fontFamilies()
                // A family that isn't installed has no row to select — show the
                // saved name rather than an empty field.
                fallbackText: fp.current
                Component.onCompleted: currentIndex = find(fp.current)
                onActivated: fp.chosen(currentText)
            }
        }

        FontPick {
            icon: "󰛖"
            title: "Interface font"
            subtitle: "Used for all UI text"
            current: Appearance.fontFamily
            onChosen: family => Appearance.setFont(family)
        }

        FontPick {
            icon: "󰀫"
            title: "Monospace & icons"
            subtitle: "Must be a Nerd-Font-patched family — every glyph comes from it"
            current: Appearance.fontMono
            onChosen: family => Appearance.setMono(family)
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.tiny
            implicitHeight: preview.implicitHeight + Theme.spacing.normal * 2
            radius: Theme.rounding.small
            color: Theme.colors.surfaceVariant

            ColumnLayout {
                id: preview
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Theme.spacing.normal
                spacing: 2
                Text {
                    text: "The quick brown fox jumps over the lazy dog"
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.medium
                    color: Theme.colors.textPrimary
                }
                Text {
                    text: "mono 0123456789  󰀄 󰕾 󰂯 󰤨 󰋜 󰅐"
                    font.family: Theme.font.mono
                    font.pointSize: Theme.font.medium
                    color: Theme.colors.textSecondary
                }
            }
        }
    }

    // --- sliders --------------------------------------------------------
    SettingsGroup {
        caption: "Sliders"
        icon: "󰡵"

        SettingsRow {
            icon: "󰕾"
            title: "Slider style"
            subtitle: "How every level slider draws — the dashboard rows and "
                + "the OSD pill under the bar"
            SegmentedControl {
                value: Appearance.sliderStyle
                options: DashboardConfig.sliderStyles
                onPicked: v => Appearance.setSliderStyle(v)
            }
        }

        SettingsRow {
            icon: "󰈈"
            title: "Preview"
            LevelBar {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 200
                Layout.preferredHeight: implicitHeight
                value: 0.62
                style: Appearance.sliderStyle
                icon: "󰕾"
                animated: true
            }
        }
    }

    // --- presets -------------------------------------------------------
    // Was its own nav page; folded in here since a preset is "everything on
    // this page (plus the bar and desktop widgets), saved together".
    SettingsGroup {
        caption: "Presets"
        icon: "󰏗"
        hint: Presets.count + (Presets.count === 1 ? " preset" : " presets")

        SettingsRow {
            icon: "󰆓"
            title: "Save current setup"
            subtitle: {
                const n = Presets.sanitize(presetNameField.text);
                if (n.length === 0)
                    return "Scheme, fonts, wallpaper, avatar, bar layout and desktop widgets — one named preset";
                if (Presets.exists(n))
                    return "“" + n + "” already exists — saving replaces it";
                return "Saves as “" + n + "”";
            }

            Rectangle {
                Layout.preferredWidth: 190
                implicitHeight: 32
                radius: height / 2
                color: Theme.colors.surfaceVariant

                TextField {
                    id: presetNameField
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
                    onAccepted: page.saveTypedPreset()
                }
            }

            PillButton {
                text: Presets.exists(presetNameField.text) ? "Overwrite" : "Save"
                accent: true
                enabledButton: Presets.sanitize(presetNameField.text).length > 0
                onClicked: page.saveTypedPreset()
            }
        }

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
            subtitle: "~/.config/quickshell/presets/ — drop a .json in; qs ipc call preset apply <name>"
            PillButton {
                text: "Reload"
                onClicked: Presets.reload()
            }
        }

        Flow {
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.tiny
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

        SettingsRow {
            visible: Presets.count === 0
            icon: "󰏗"
            title: "No presets yet"
            subtitle: "Get the shell looking right, then name it above and save"
        }
    }
}
