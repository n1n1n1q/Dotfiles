import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.modules.settings

// Google Calendar / Tasks account + display settings. The bar clock's calendar
// dropdown (modules/popout/CalendarCard) shows the synced events and tasks.
SettingsPage {
    id: page
    heading: "Calendar"
    icon: "󰃭"
    blurb: "Connect Google accounts to see their events and tasks in the bar's "
        + "calendar dropdown. Setup instructions: docs/google-setup.md in the config."

    function _ago(iso) {
        if (!iso) return "never";
        const t = new Date(iso).getTime();
        if (isNaN(t)) return "never";
        const s = Math.round((Date.now() - t) / 1000);
        if (s < 60) return "just now";
        if (s < 3600) return Math.round(s / 60) + " min ago";
        if (s < 86400) return Math.round(s / 3600) + " h ago";
        return Math.round(s / 86400) + " d ago";
    }

    // --- credentials ------------------------------------------------
    SettingsGroup {
        caption: "Google account"
        icon: "󰊫"

        SettingsRow {
            visible: !GoogleCalendar.hasClient
            icon: "󰌆"
            title: "OAuth client"
            subtitle: "Create a Google Cloud project, enable the Calendar + Tasks "
                + "APIs, make a 'Desktop app' OAuth client, then paste its ID and "
                + "secret here. Full steps in docs/google-setup.md."
        }

        Rectangle {
            visible: !GoogleCalendar.hasClient
            Layout.fillWidth: true
            implicitHeight: creds.implicitHeight + Theme.spacing.medium * 2
            radius: Theme.rounding.large
            color: Theme.colors.surfaceVariant

            ColumnLayout {
                id: creds
                anchors.fill: parent
                anchors.margins: Theme.spacing.medium
                spacing: Theme.spacing.small

                WifiField { id: cidField;  placeholder: "Client ID";     icon: "󰀫" }
                WifiField { id: csecField; placeholder: "Client secret"; icon: "󰌆"; secret: true }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    PillButton {
                        text: "Save credentials"
                        accent: true
                        enabledButton: cidField.text.trim().length > 0
                            && csecField.text.trim().length > 0
                        onClicked: {
                            GoogleCalendar.writeClient(cidField.text.trim(), csecField.text.trim());
                            cidField.clear();
                            csecField.clear();
                        }
                    }
                }
            }
        }

        SettingsRow {
            visible: GoogleCalendar.hasClient
            icon: "󰐕"
            title: "Add account"
            subtitle: GoogleCalendar.loggingIn
                ? "Waiting for the browser…"
                : "Opens your browser to sign in with Google"
            BusyIndicator {
                visible: GoogleCalendar.loggingIn
                running: visible
                implicitWidth: 22
                implicitHeight: 22
            }
            PillButton {
                visible: !GoogleCalendar.loggingIn
                text: "Add"
                onClicked: GoogleCalendar.login()
            }
        }

        Repeater {
            model: GoogleCalendar.accounts
            delegate: SettingsRow {
                required property var modelData
                icon: modelData.error ? "󰀧" : "󰊫"
                title: modelData.email
                subtitle: modelData.error === "reauth"
                    ? "Needs re-authentication — the refresh token expired"
                    : modelData.error
                        ? ("Sync error: " + modelData.error)
                        : "Connected"

                PillButton {
                    visible: !!modelData.error
                    text: "Reconnect"
                    accent: true
                    onClicked: GoogleCalendar.login()
                }
                PillButton {
                    text: "Remove"
                    danger: true
                    onClicked: GoogleCalendar.logout(modelData.email)
                }
            }
        }

        SettingsRow {
            visible: GoogleCalendar.connected
            icon: "󰓦"
            title: "Sync now"
            subtitle: "Last synced " + page._ago(GoogleCalendar.syncedAt)
            BusyIndicator {
                visible: GoogleCalendar.syncing
                running: visible
                implicitWidth: 22
                implicitHeight: 22
            }
            PillButton {
                visible: !GoogleCalendar.syncing
                text: "Sync"
                onClicked: GoogleCalendar.syncNow()
            }
        }

        SettingsRow {
            visible: GoogleCalendar.connected
            compact: true
            icon: "󰔛"
            title: "Sync every"
            SettingsSpin {
                from: 5
                to: 240
                step: 5
                suffix: " min"
                value: GoogleConfig.syncIntervalMin
                onStepped: v => GoogleConfig.setSyncInterval(v)
            }
        }

        SettingsRow {
            visible: GoogleCalendar.lastError.length > 0
            icon: "󰀧"
            title: "Last error"
            subtitle: GoogleCalendar.lastError
        }
    }

    // --- calendars ------------------------------------------------
    SettingsGroup {
        caption: "Calendars"
        icon: "󰸗"
        visible: GoogleCalendar.connected && GoogleCalendar.calendars.length > 0

        Repeater {
            model: GoogleCalendar.calendars
            delegate: SettingsRow {
                required property var modelData
                icon: "󰃭"
                title: modelData.summary
                subtitle: modelData.accountEmail
                    + (modelData.primary ? "  ·  primary" : "")

                Rectangle {
                    implicitWidth: 12
                    implicitHeight: 12
                    radius: 6
                    color: modelData.bg || Theme.colors.accent
                }
                SettingsToggle {
                    checked: !GoogleConfig.isCalendarHidden(modelData.key)
                    onToggled: v => GoogleConfig.setCalendarHidden(modelData.key, !v)
                }
            }
        }
    }

    // --- tasks --------------------------------------------------
    SettingsGroup {
        caption: "Tasks"
        icon: "󰄴"
        visible: GoogleCalendar.connected

        SettingsRow {
            visible: GoogleCalendar.taskLists.length > 0
            icon: "󰝔"
            title: "Quick-add list"
            subtitle: "Where the calendar dropdown's 'Add a task' field puts new tasks"
            SettingsCombo {
                Layout.preferredWidth: 200
                model: GoogleCalendar.taskLists.map(l => l.title + "  (" + l.accountEmail + ")")
                currentIndex: {
                    const k = GoogleConfig.defaultTaskListKey;
                    const i = GoogleCalendar.taskLists.findIndex(l => l.key === k);
                    return i >= 0 ? i : 0;
                }
                onActivated: GoogleConfig.setDefaultTaskList(
                    GoogleCalendar.taskLists[currentIndex].key)
            }
        }

        SettingsRow {
            compact: true
            icon: "󰄲"
            title: "Show completed tasks"
            SettingsToggle {
                checked: GoogleConfig.showCompletedTasks
                onToggled: v => GoogleConfig.setShowCompleted(v)
            }
        }
    }

    // --- data note --------------------------------------------
    SettingsGroup {
        caption: "Your data"
        icon: "󰆼"

        SettingsRow {
            icon: "󰉋"
            title: "Where it's stored"
            subtitle: "Tokens and synced data live in ~/.config/quickshell/google/ "
                + "(files mode 600, git-ignored). Remove an account to revoke and delete it."
        }
        SettingsRow {
            icon: "󰥔"
            title: "Weekly re-login"
            subtitle: "While your OAuth app is in 'Testing' status Google expires the "
                + "refresh token after 7 days. Hit 'Publish app' on the consent screen "
                + "to stop that (no verification needed for personal use)."
        }
    }

    SettingsPlaceholder {
        visible: !GoogleCalendar.connected && GoogleCalendar.hasClient
        icon: "󰊫"
        label: "No account connected"
        hint: "Add a Google account above to pull in its calendars and tasks."
    }
}
