import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets
import qs.config
import qs.services
import qs.modules.settings

// Settings for the app launcher — `qs ipc call launcher toggle`, or the
// Launcher tile in the dashboard. Persisted to launcher.json; the usage
// counter behind "most used first" lives in launcher-usage.json next to it.
SettingsPage {
    id: page
    heading: "Launcher"
    icon: "󱓞"
    blurb: "The search card that drops in under the bar. It looks through your "
        + "installed applications, and hands anything that isn't one to bash, "
        + "the calculator or a web search."

    readonly property int trackedApps: Object.keys(Apps.usage).length

    // --- search -------------------------------------------------------------
    SettingsGroup {
        caption: "Search"
        icon: "󰍉"

        SettingsRow {
            icon: "󰦨"
            title: "Results shown"
            subtitle: "How long the list is allowed to get before it scrolls"
            SettingsSpin {
                from: 3
                to: 30
                step: 1
                value: LauncherConfig.maxResults
                onStepped: v => LauncherConfig.setMaxResults(v)
            }
        }

        SettingsRow {
            icon: "󰐳"
            title: "Most used first"
            subtitle: LauncherConfig.frecency
                ? "Apps you open often win ties, and fill the list before you type"
                : "Matches are ranked on the query alone, then by name"
            SettingsToggle {
                checked: LauncherConfig.frecency
                onToggled: v => LauncherConfig.setFrecency(v)
            }
        }

        SettingsRow {
            icon: "󰃢"
            title: "Usage history"
            subtitle: page.trackedApps === 0
                ? "Nothing recorded yet"
                : page.trackedApps + " app" + (page.trackedApps === 1 ? "" : "s")
                  + " counted so far"
            PillButton {
                text: "Forget"
                danger: true
                enabledButton: page.trackedApps > 0
                onClicked: Apps.forget()
            }
        }
    }

    // --- the other three modes ----------------------------------------------
    SettingsGroup {
        caption: "Beyond apps"
        icon: "󰘳"
        hint: "prefixes are set in launcher.json"

        SettingsRow {
            icon: "󰌒"
            title: "Offer them without a prefix"
            subtitle: LauncherConfig.showExtras
                ? "A command, a sum and a web search trail every app search"
                : "Only reachable by opening the line with their prefix"
            SettingsToggle {
                checked: LauncherConfig.showExtras
                onToggled: v => LauncherConfig.setShowExtras(v)
            }
        }

        SettingsRow {
            compact: true
            icon: "󰖟"
            title: "Search engine"
            subtitle: "Where a web search opens"
            SettingsCombo {
                Layout.preferredWidth: 160
                model: LauncherConfig.engines.map(e => e.name)
                // A URL typed into the file by hand has no row to select, so
                // the field shows the URL itself rather than sitting empty.
                fallbackText: LauncherConfig.webSearchUrl
                Component.onCompleted: currentIndex = find(LauncherConfig.engineName)
                onActivated: {
                    const e = LauncherConfig.engines.find(x => x.name === currentText);
                    if (e) LauncherConfig.setWebSearchUrl(e.url);
                }
            }
        }

        SettingsRow {
            compact: true
            icon: "󰆍"
            title: "Terminal"
            subtitle: "Used for apps whose .desktop file asks for one"
            SettingsCombo {
                Layout.preferredWidth: 160
                model: LauncherConfig.terminals
                fallbackText: LauncherConfig.terminal
                Component.onCompleted: currentIndex = find(LauncherConfig.terminal)
                onActivated: LauncherConfig.setTerminal(currentText)
            }
        }

        // The prefixes themselves aren't editable here — they're one character
        // each and live in the file — but the launcher's own footer is easy to
        // miss, so they're spelled out once somewhere findable.
        SettingsCaption {
            text: "Open a line with "
                + LauncherConfig.modes.map(m => m.prefix + " for " + m.name.toLowerCase()).join(", ")
                + "."
        }
    }

    // --- favourites & hidden ----------------------------------------------
    // A chip list + an "add" dropdown, sitting as its own card in the group.
    // Right-clicking a launcher row pins / hides too, but a hidden app can't be
    // right-clicked back, so it's undone here.
    component AppChips: Rectangle {
        id: ed
        property var ids: []                 // array of .desktop ids
        property string blurb: ""
        property var onRemove: function (id) {}
        property var onAdd: function (id) {}
        readonly property var addable: Apps.catalogue
            .filter(a => ed.ids.indexOf(a.id) < 0)

        Layout.fillWidth: true
        Layout.columnSpan: 2
        implicitHeight: edCol.implicitHeight + Theme.spacing.medium * 2
        radius: Theme.rounding.xhuge
        color: Theme.colors.surfaceVariant

        ColumnLayout {
            id: edCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.spacing.large
            anchors.rightMargin: Theme.spacing.large
            spacing: Theme.spacing.small

            Text {
                Layout.fillWidth: true
                visible: ed.blurb.length > 0
                text: ed.blurb
                wrapMode: Text.WordWrap
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }

            Flow {
                Layout.fillWidth: true
                visible: ed.ids.length > 0
                spacing: Theme.spacing.tiny

                Repeater {
                    model: ed.ids
                    delegate: Rectangle {
                        id: chip
                        required property var modelData
                        readonly property var entry: Apps.entryById(modelData)
                        implicitWidth: chipRow.implicitWidth + Theme.spacing.small * 2
                        implicitHeight: 28
                        radius: Theme.rounding.small
                        color: Theme.palette.surface2

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: Theme.spacing.tiny

                            IconImage {
                                visible: !!chip.entry
                                implicitWidth: 16
                                implicitHeight: 16
                                source: chip.entry ? Apps.iconSource(chip.entry) : ""
                            }
                            Text {
                                text: chip.entry ? chip.entry.name : chip.modelData
                                font.family: Theme.font.main
                                font.pointSize: Theme.font.small
                                color: Theme.colors.textPrimary
                            }
                            Text {
                                text: "󰅖"
                                font.family: Theme.font.icon
                                font.pointSize: Theme.font.tiny
                                color: Theme.colors.textTertiary
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -5
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ed.onRemove(chip.modelData)
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: ed.ids.length === 0
                text: "None yet"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }

            SettingsCombo {
                Layout.preferredWidth: 220
                model: [""].concat(ed.addable.map(a => a.name))
                fallbackText: "Add an app…"
                currentIndex: 0
                onActivated: {
                    if (currentIndex <= 0)
                        return;
                    const a = ed.addable[currentIndex - 1];
                    if (a) ed.onAdd(a.id);
                    currentIndex = 0;
                }
            }
        }
    }

    SettingsGroup {
        caption: "Favourites"
        icon: "󰐃"

        AppChips {
            ids: LauncherConfig.favoriteIds
            blurb: "Pinned apps lead the list when the launcher opens and win "
                + "ties once you type. Right-click any row to pin it too."
            onRemove: id => LauncherConfig.removeFavorite(id)
            onAdd: id => LauncherConfig.toggleFavorite(id)
        }
    }

    SettingsGroup {
        caption: "Hidden apps"
        icon: "󰈉"

        AppChips {
            ids: LauncherConfig.hiddenIds
            blurb: "Excluded from the launcher entirely. Right-click a row to "
                + "hide it; add it back here."
            onRemove: id => LauncherConfig.removeHidden(id)
            onAdd: id => LauncherConfig.toggleHidden(id)
        }
    }
}
