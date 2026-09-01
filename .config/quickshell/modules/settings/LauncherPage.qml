import QtQuick
import QtQuick.Layouts
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
            icon: "󰖟"
            title: "Search engine"
            subtitle: "Where a web search opens"
            SettingsCombo {
                Layout.preferredWidth: 190
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
            icon: "󰆍"
            title: "Terminal"
            subtitle: "Used for apps whose .desktop file asks for one"
            SettingsCombo {
                Layout.preferredWidth: 190
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

    // --- reset ---------------------------------------------------------------
    SettingsGroup {
        caption: "Reset"
        icon: "󰑏"

        SettingsRow {
            icon: "󰑏"
            title: "Reset to default"
            subtitle: "Restore the shipped launcher settings, prefixes included"
            PillButton {
                text: "Reset"
                danger: true
                onClicked: LauncherConfig.reset()
            }
        }
    }
}
