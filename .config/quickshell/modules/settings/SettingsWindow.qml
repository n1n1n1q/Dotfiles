import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config

// The settings window: a floating xdg-toplevel (not a layer-shell surface, so
// toggling `visible` is safe here). Qt's titlebar is suppressed via
// QT_WAYLAND_DISABLE_WINDOWDECORATION in shell.qml — the in-window X closes it.
// One instance lives in shell.qml; SettingsController drives it.
//
// Layout follows end-4's: a slim title strip across the top, a narrow icon+label
// rail down the left that collapses to icons, and the page itself carrying no
// title of its own — section headers do that work.
FloatingWindow {
    id: root

    visible: SettingsController.open
    title: "Shell Settings"
    implicitWidth: 1000
    implicitHeight: 660
    minimumSize: Qt.size(760, 520)
    color: Theme.bar.background

    onVisibleChanged: if (!visible && SettingsController.open) SettingsController.open = false

    // Nav groups exist only for the gaps between runs of entries — there are no
    // group headers. `search` is matched against but never shown. Flattened
    // order (`sections`) must match the StackLayout children below.
    readonly property var navGroups: [
        [ { slug: "welcome", icon: "󰋜", title: "Home", subtitle: "Overview", search: "welcome start" } ],
        // What the shell looks like, then what each of its surfaces is made of.
        [
            { slug: "appearance", icon: "󰏘", title: "Appearance", subtitle: "Colours, wallpaper, fonts", search: "general theme colour color scheme font avatar profile picture background look" }
        ],
        [
            { slug: "bar",           icon: "󰟀", title: "Bar",           subtitle: "Top bar layout",      search: "customization rice frame corners popout" },
            { slug: "dashboard",     icon: "󰕮", title: "Dashboard",     subtitle: "Tiles & sliders",     search: "customization rice panel quick settings" },
            { slug: "launcher",      icon: "󱓞", title: "Launcher",      subtitle: "App search",          search: "run open spotlight rofi fuzzel command math web" },
            { slug: "widgets",       icon: "󰀻", title: "Widgets",       subtitle: "Desktop widgets",     search: "customization rice clock desktop stats" },
            { slug: "notifications", icon: "󰎟", title: "Notifications", subtitle: "Toasts & OSD",        search: "popup toast osd on-screen display slider volume brightness corner" },
            { slug: "presets",       icon: "󰏗", title: "Presets",       subtitle: "Saved setups",        search: "customization rice save theme profile" }
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
        [ { slug: "about", icon: "󰋽", title: "About", subtitle: "Shell & credits", search: "version credits" } ]
    ]

    readonly property var sections: {
        let out = [];
        for (const g of navGroups)
            for (const s of g)
                out.push(s);
        return out;
    }

    property string query: ""
    property bool railCollapsed: false

    readonly property int railWidth: railCollapsed ? 60 : 208

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

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // --- title strip ------------------------------------------------
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 46

                Text {
                    anchors.centerIn: parent
                    text: "Settings"
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.large
                    font.weight: Theme.font.mediumWeight
                    color: Theme.colors.textPrimary
                }

                // The window has no titlebar of its own — this is the way out.
                IconButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: Theme.spacing.normal
                    icon: "󰅖"
                    round: true
                    size: 32
                    onClicked: SettingsController.hide()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // --- navigation rail ---------------------------------------
                Item {
                    Layout.preferredWidth: root.railWidth
                    Layout.fillHeight: true

                    Behavior on Layout.preferredWidth {
                        NumberAnimation {
                            duration: Theme.animation.normal
                            easing.type: Easing.OutCubic
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing.small
                        anchors.rightMargin: Theme.spacing.small
                        anchors.topMargin: Theme.spacing.tiny
                        anchors.bottomMargin: Theme.spacing.small
                        spacing: Theme.spacing.small

                        // Collapse control, plus the search box while there is
                        // room for it.
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing.tiny

                            IconButton {
                                icon: "󰍜"
                                round: true
                                size: 34
                                tooltip: root.railCollapsed ? "Expand" : "Collapse"
                                onClicked: root.railCollapsed = !root.railCollapsed
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                visible: !root.railCollapsed
                                implicitHeight: 34
                                radius: height / 2
                                color: Theme.colors.surface

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacing.normal
                                    anchors.rightMargin: Theme.spacing.small
                                    spacing: Theme.spacing.tiny

                                    Text {
                                        text: "󰍉"
                                        font.family: Theme.font.icon
                                        font.pointSize: Theme.font.normal
                                        color: Theme.colors.textTertiary
                                    }

                                    TextField {
                                        Layout.fillWidth: true
                                        placeholderText: "Search"
                                        color: Theme.colors.textPrimary
                                        placeholderTextColor: Theme.colors.textTertiary
                                        font.family: Theme.font.main
                                        font.pointSize: Theme.font.small
                                        leftPadding: 0
                                        rightPadding: 0
                                        background: Item {}
                                        onTextChanged: root.query = text
                                    }
                                }
                            }
                        }

                        // Entry list. Scrolls only when it overflows a short
                        // window.
                        Flickable {
                            id: navFlick

                            readonly property bool scrollable: contentHeight > height

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: width
                            contentHeight: navCol.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            // A live Flickable steals the press from whatever is
                            // under it once the pointer drifts past the drag
                            // threshold — which reads as a nav entry that simply
                            // didn't take the click. Nothing to scroll, nothing
                            // to drag.
                            interactive: scrollable

                            // The Basic style keeps the scrollbar mapped and
                            // interactive whenever the policy isn't AlwaysOff —
                            // it only fades the *handle* out — so by default it
                            // owns a dead strip down the right edge of every nav
                            // row. Hide it when it can't scroll, and keep the
                            // rows out from under it when it can.
                            ScrollBar.vertical: ScrollBar {
                                id: navScroll
                                policy: ScrollBar.AsNeeded
                                visible: navFlick.scrollable
                            }

                            ColumnLayout {
                                id: navCol
                                width: navFlick.width - (navScroll.visible ? navScroll.width : 0)
                                spacing: 2

                                Repeater {
                                    model: root.navGroups

                                    delegate: ColumnLayout {
                                        required property var modelData
                                        required property int index

                                        Layout.fillWidth: true
                                        Layout.topMargin: index === 0 ? 0 : Theme.spacing.small
                                        spacing: 2

                                        Repeater {
                                            model: modelData

                                            delegate: NavEntry {
                                                required property var modelData
                                                visible: root.matches(modelData)
                                                icon: modelData.icon
                                                title: modelData.title
                                                subtitle: modelData.subtitle
                                                collapsed: root.railCollapsed
                                                selected: SettingsController.section === modelData.slug
                                                onClicked: SettingsController.section = modelData.slug
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // --- content ------------------------------------------------
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: Theme.spacing.small
                    Layout.rightMargin: Theme.spacing.medium
                    Layout.topMargin: Theme.spacing.tiny
                    Layout.bottomMargin: Theme.spacing.small
                    currentIndex: root.sectionIndex(SettingsController.section)

                    WelcomePage {
                        onNavigate: slug => SettingsController.section = slug
                    }
                    AppearancePage {}
                    BarPage {}
                    DashboardPage {}
                    LauncherPage {}
                    WidgetsPage {}
                    NotificationsPage {}
                    PresetsPage {}
                    WiFiPage {}
                    BluetoothPage {}
                    SoundPage {}
                    DisplayPage {}
                    KeyboardPage {}
                    NiriPage {}
                    AboutPage {}
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: SettingsController.hide()
    }
}
