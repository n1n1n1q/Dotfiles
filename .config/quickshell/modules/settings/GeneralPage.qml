import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import qs.config
import qs.services
import qs.modules.settings

SettingsPage {
    id: page
    heading: "General"
    icon: "󰒓"
    blurb: "Profile, colours and fonts. Colour schemes are JSON files in "
        + "~/.config/quickshell/colorschemes/."

    // --- profile ---------------------------------------------------------
    SettingsGroup {
        caption: "Profile"

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
    Flow {
        Layout.fillWidth: true
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
        icon: "󰉋"
        title: "Scheme files"
        subtitle: "~/.config/quickshell/colorschemes/ — add a .json to define your own"
        PillButton {
            text: "Reload"
            onClicked: Appearance.reloadSchemes()
        }
    }

    // --- fonts ----------------------------------------------------------------
    SettingsGroup {
        caption: "Fonts"

        component FontPick: SettingsRow {
            id: fp
            property string current: ""
            signal chosen(string family)

            ComboBox {
                Layout.preferredWidth: 220
                model: Qt.fontFamilies()
                editable: true
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                Component.onCompleted: {
                    const i = find(fp.current);
                    if (i >= 0) currentIndex = i; else editText = fp.current;
                }
                onActivated: fp.chosen(currentText)
                onAccepted: fp.chosen(editText)
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

    // rescan the wallpapers folder whenever the settings window opens or the
    // user navigates here, so images added outside the shell show up
    Connections {
        target: SettingsController
        function onOpenChanged() { if (SettingsController.open) Wallpaper.reload(); }
        function onSectionChanged() { if (SettingsController.section === "general") Wallpaper.reload(); }
    }

    // --- wallpaper -------------------------------------------------------
    SettingsGroup {
        caption: "Wallpaper"

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
}
