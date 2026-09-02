import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config

// The settings window: a regular floating xdg-toplevel (not a layer-shell
// surface, so toggling `visible` is safe here). Qt's titlebar is suppressed via
// QT_WAYLAND_DISABLE_WINDOWDECORATION in shell.qml — the floating X closes it.
// One instance lives in shell.qml; SettingsController drives it.
//
// Layout takes after Caelestia's "Nexus": a wide icon+label rail down the left
// with a big search field above it, and the page filling the rest — the page
// carries its own large title, no global title strip.
FloatingWindow {
    id: root

    visible: SettingsController.open
    title: "Shell Settings"
    implicitWidth: 1120
    implicitHeight: 740
    minimumSize: Qt.size(840, 560)
    color: Theme.bar.background

    onVisibleChanged: if (!visible && SettingsController.open) SettingsController.open = false

    // Nav groups exist only for the gaps between runs of entries — there are no
    // group headers. `search` is matched against but never shown. Flattened
    // order (`sections`) must match the StackLayout children below.
    readonly property var navGroups: [
        [ { slug: "welcome", icon: "󰋜", title: "Home", subtitle: "Overview", search: "welcome start" } ],
        // Connectivity up top — the pages reached for most often.
        [
            { slug: "wifi",      icon: "󰤨", title: "Wi‑Fi",     subtitle: "Wireless networking", search: "system network" },
            { slug: "bluetooth", icon: "󰂯", title: "Bluetooth", subtitle: "Devices & pairing",   search: "system" },
            { slug: "sound",     icon: "󰕾", title: "Sound",     subtitle: "Output & input",       search: "system audio volume" },
            { slug: "calendar",  icon: "󰃭", title: "Calendar",  subtitle: "Google account & tasks", search: "google calendar tasks events sync account todo oauth agenda gmail" }
        ],
        // What the shell looks like, then what each of its surfaces is made of.
        [
            { slug: "general", icon: "󰏘", title: "General", subtitle: "Colours, wallpaper, fonts, presets", search: "appearance theme colour color scheme font avatar profile picture background look preset save profile rice" }
        ],
        [
            { slug: "bar",           icon: "󰟀", title: "Bar",           subtitle: "Top bar layout",      search: "customization rice frame corners popout" },
            { slug: "launcher",      icon: "󱓞", title: "Launcher",      subtitle: "App search",          search: "run open spotlight rofi fuzzel command math web" },
            { slug: "widgets",       icon: "󰀻", title: "Widgets",       subtitle: "Desktop widgets",     search: "customization rice clock desktop stats" },
            { slug: "notifications", icon: "󰎟", title: "Notifications", subtitle: "Toasts & OSD",        search: "popup toast osd on-screen display slider volume brightness corner" }
        ],
        [
            { slug: "display",  icon: "󰍹", title: "Display",  subtitle: "Monitors",        search: "monitor screen" },
            { slug: "keyboard", icon: "󰌌", title: "Keyboard", subtitle: "Layout & input",  search: "input layout" },
            { slug: "keybinds", icon: "󰥻", title: "Keybinds", subtitle: "Keyboard shortcuts", search: "shortcut hotkey bind key niri" },
            { slug: "niri",     icon: "󱂬", title: "niri",     subtitle: "Compositor",      search: "compositor input" },
            { slug: "lock",     icon: "󰌾", title: "Lock screen", subtitle: "Idle & security", search: "lock idle swayidle sleep suspend password screensaver security timeout" }
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
        id: shell
        anchors.fill: parent
        color: Theme.bar.background

        // Click anywhere that isn't a control → drop the search field's focus.
        // Sits behind the content (clicks on real controls hit those first).
        MouseArea {
            anchors.fill: parent
            z: -1
            onPressed: mouse => { searchInput.focus = false; mouse.accepted = false; }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacing.xlarge
            spacing: Theme.spacing.xlarge

            // --- navigation rail -------------------------------------------
            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: false
                Layout.preferredWidth: Math.round(Math.max(258, Math.min(330, shell.width * 0.26)))
                spacing: Theme.spacing.large

                // Search field
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: Theme.rounding.full
                    color: Theme.colors.surface
                    border.width: 1
                    border.color: searchInput.activeFocus ? Theme.colors.accent : Theme.colors.borderSubtle

                    Behavior on border.color { ColorAnimation { duration: Theme.animation.fast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing.large
                        anchors.rightMargin: Theme.spacing.normal
                        spacing: Theme.spacing.small

                        Text {
                            text: "󰍉"
                            font.family: Theme.font.icon
                            font.pointSize: Theme.font.large
                            color: Theme.colors.textTertiary
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            placeholderText: "Search settings"
                            color: Theme.colors.textPrimary
                            placeholderTextColor: Theme.colors.textTertiary
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.medium
                            leftPadding: 0
                            rightPadding: 0
                            background: Item {}
                            onTextChanged: root.query = text
                            onAccepted: focus = false
                            // Esc clears the query first, then drops focus —
                            // only closing the window once the field is empty
                            // and unfocused (see the Shortcut below).
                            Keys.onEscapePressed: event => {
                                if (text.length > 0) text = "";
                                else focus = false;
                                event.accepted = true;
                            }
                        }
                    }
                }

                // Entry list — scrolls only when it overflows.
                Flickable {
                    id: navFlick

                    readonly property bool scrollable: contentHeight > height

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: navCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: scrollable

                    ScrollBar.vertical: ScrollBar {
                        id: navScroll
                        policy: ScrollBar.AsNeeded
                        visible: navFlick.scrollable
                    }

                    ColumnLayout {
                        id: navCol
                        width: navFlick.width - (navScroll.visible ? navScroll.width + Theme.spacing.small : 0)
                        spacing: Theme.spacing.tiny

                        Repeater {
                            model: root.navGroups

                            delegate: ColumnLayout {
                                id: navGroupItem
                                required property var modelData
                                required property int index
                                readonly property var entries: modelData

                                Layout.fillWidth: true
                                Layout.topMargin: index === 0 ? 0 : Theme.spacing.medium
                                // Entries in a group sit close so their
                                // segmented rounding reads as one block.
                                spacing: Theme.spacing.tiny

                                Repeater {
                                    model: navGroupItem.entries

                                    delegate: NavEntry {
                                        required property var modelData
                                        required property int index
                                        visible: root.matches(modelData)
                                        icon: modelData.icon
                                        title: modelData.title
                                        subtitle: modelData.subtitle
                                        selected: SettingsController.section === modelData.slug
                                        blockPosition: root.query.length > 0
                                                || navGroupItem.entries.length === 1 ? "single"
                                            : index === 0 ? "top"
                                            : index === navGroupItem.entries.length - 1 ? "bottom"
                                            : "middle"
                                        onClicked: SettingsController.section = modelData.slug
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --- content --------------------------------------------------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                StackLayout {
                    anchors.fill: parent
                    currentIndex: root.sectionIndex(SettingsController.section)

                    // Order MUST match the flattened `sections` list above.
                    WelcomePage {
                        onNavigate: slug => SettingsController.section = slug
                    }
                    WiFiPage {}
                    BluetoothPage {}
                    SoundPage {}
                    CalendarPage {}
                    GeneralPage {}
                    BarPage {}
                    LauncherPage {}
                    WidgetsPage {}
                    NotificationsPage {}
                    DisplayPage {}
                    KeyboardPage {}
                    KeybindsPage {}
                    NiriPage {}
                    LockPage {}
                    AboutPage {}
                }

                // Floating close button, over the top-right of the content.
                IconButton {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    icon: "󰅖"
                    round: true
                    size: 40
                    onClicked: SettingsController.hide()
                }
            }
        }
    }

    // Escape does NOT close the window (too easy to lose your place mid-edit) —
    // it only clears / unfocuses the search field, handled on the field itself.
    // Close with the X or by toggling the keybind.
}
