import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config

// The settings window: a floating xdg-toplevel (not a layer-shell surface, so
// toggling `visible` is safe here). Qt's titlebar is suppressed via
// QT_WAYLAND_DISABLE_WINDOWDECORATION in shell.qml — the in-window X closes it.
// One instance lives in shell.qml; SettingsController drives it.
FloatingWindow {
    id: root

    visible: SettingsController.open
    title: "Shell Settings"
    implicitWidth: 1040
    implicitHeight: 680
    minimumSize: Qt.size(820, 540)
    color: Theme.bar.background

    onVisibleChanged: if (!visible && SettingsController.open) SettingsController.open = false

    // Nav is grouped only for spacing + segmented rounding — no group headers.
    // `search` is matched against but never shown. Flattened order (`sections`)
    // must match the StackLayout children below.
    readonly property var navGroups: [
        [ { slug: "welcome", icon: "󰋜", title: "Welcome", subtitle: "Overview", search: "" } ],
        [
            { slug: "general", icon: "󰒓", title: "General", subtitle: "Profile, colours, fonts", search: "appearance theme wallpaper" }
        ],
        [
            { slug: "wifi",      icon: "󰤨", title: "Wi‑Fi",     subtitle: "Wireless networking", search: "system network" },
            { slug: "bluetooth", icon: "󰂯", title: "Bluetooth", subtitle: "Devices & pairing",   search: "system" },
            { slug: "sound",     icon: "󰕾", title: "Sound",     subtitle: "Output & input",       search: "system audio volume" }
        ],
        [
            { slug: "display",  icon: "󰍹", title: "Display",  subtitle: "Monitors",        search: "monitor screen" },
            { slug: "keyboard", icon: "󰌌", title: "Keyboard", subtitle: "Layout & input",  search: "input layout" },
            { slug: "niri",     icon: "󱂬", title: "niri",     subtitle: "Compositor",      search: "compositor input" }
        ],
        [
            { slug: "bar",       icon: "󰟀", title: "Bar",       subtitle: "Top bar layout",  search: "customization rice" },
            { slug: "widgets",   icon: "󰀻", title: "Widgets",   subtitle: "Bar & dashboard", search: "customization rice" },
            { slug: "dashboard", icon: "󰕮", title: "Dashboard", subtitle: "Panel sections",  search: "customization rice" }
        ],
        [ { slug: "about", icon: "󰋽", title: "About", subtitle: "Shell & credits", search: "" } ]
    ]

    readonly property var sections: {
        let out = [];
        for (const g of navGroups)
            for (const s of g)
                out.push(s);
        return out;
    }

    property string query: ""

    function sectionIndex(slug) {
        for (let i = 0; i < sections.length; i++)
            if (sections[i].slug === slug)
                return i;
        return 0;
    }
    function matches(s) {
        if (query.length === 0)
            return true;
        const q = query.toLowerCase();
        return s.title.toLowerCase().indexOf(q) !== -1
            || s.search.toLowerCase().indexOf(q) !== -1;
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bar.background

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // --- Sidebar : content  ≈  1 : 1.7 -------------------------------
            Item {
                Layout.preferredWidth: Math.round(root.width / 2.7)
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.large
                    spacing: Theme.spacing.medium

                    // Search box — bar-pill styling.
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        radius: Theme.workspace.indicatorRadius
                        color: Theme.workspace.background

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacing.normal
                            anchors.rightMargin: Theme.spacing.normal
                            spacing: Theme.spacing.small

                            Text {
                                text: "󰍉"
                                font.family: Theme.font.icon
                                font.pointSize: Theme.font.medium
                                color: Theme.colors.textTertiary
                            }

                            TextField {
                                Layout.fillWidth: true
                                placeholderText: "Search settings"
                                color: Theme.colors.textPrimary
                                placeholderTextColor: Theme.colors.textTertiary
                                font.family: Theme.font.main
                                font.pointSize: Theme.font.medium
                                background: Item {}
                                onTextChanged: root.query = text
                            }
                        }
                    }

                    // Nav list — one SettingsGroup per navGroup (spacing 0 so the
                    // entries touch and only the run's ends round); padding
                    // between the groups.
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Theme.spacing.small

                        Repeater {
                            model: root.navGroups

                            delegate: SettingsGroup {
                                required property var modelData
                                spacing: 0

                                Repeater {
                                    model: modelData

                                    delegate: NavEntry {
                                        required property var modelData
                                        visible: root.matches(modelData)
                                        icon: modelData.icon
                                        title: modelData.title
                                        subtitle: modelData.subtitle
                                        selected: SettingsController.section === modelData.slug
                                        onClicked: SettingsController.section = modelData.slug
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // --- Content ----------------------------------------------------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                StackLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.xlarge
                    anchors.topMargin: Theme.spacing.large
                    anchors.rightMargin: Theme.spacing.xlarge + 44
                    currentIndex: root.sectionIndex(SettingsController.section)

                    WelcomePage {
                        onNavigate: slug => SettingsController.section = slug
                    }
                    GeneralPage {}
                    WiFiPage {}
                    BluetoothPage {}
                    SoundPage {}
                    DisplayPage {}
                    KeyboardPage {}
                    NiriPage {}
                    BarPage {}
                    WidgetsPage {}
                    DashboardPage {}
                    AboutPage {}
                }

                // Close — the window has no titlebar, this is the way out.
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: Theme.spacing.large
                    anchors.rightMargin: Theme.spacing.xlarge
                    width: 34
                    height: 34
                    radius: height / 2
                    color: closeArea.containsMouse ? Theme.colors.surfaceVariant : Theme.workspace.background

                    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Theme.font.icon
                        font.pointSize: Theme.font.medium
                        color: closeArea.containsMouse ? Theme.colors.textPrimary : Theme.colors.textSecondary
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SettingsController.hide()
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: SettingsController.hide()
    }
}
