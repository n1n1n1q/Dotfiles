import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Notification centre for the dashboard: the full `Notifications.list` history,
// newest first. With DashboardConfig.notifGrouping off that's one card per
// notification; set to "source" it's one collapsed stack per app, each opening
// into its own run. Sits inside the dashboard's own ScrollView, so it just
// grows - no nested scrolling.
ColumnLayout {
    id: root
    spacing: Theme.spacing.tiny

    // Emitted when a notification is clicked through to its app - the
    // dashboard should get out of the way.
    signal closeRequested()

    readonly property bool grouped: DashboardConfig.notifGrouped

    // [{ appName, entries }] in the order each source last spoke - so a group
    // rises to the top when it gets something new, and the list still reads
    // newest-first.
    readonly property var groups: {
        if (!grouped)
            return [];
        const byApp = {};
        const out = [];
        for (const e of Notifications.list) {
            const key = e.appName || "Notification";
            if (byApp[key] === undefined) {
                byApp[key] = { appName: key, entries: [] };
                out.push(byApp[key]);
            }
            byApp[key].entries.push(e);
        }
        return out;
    }

    // Which sources are dropped open, by app name. Kept here rather than in the
    // group delegates because the Repeater below rebuilds all of them whenever
    // a notification arrives or is dismissed.
    property var expandedSources: ({})

    function toggleSource(appName) {
        const m = Object.assign({}, root.expandedSources);
        m[appName] = !m[appName];
        root.expandedSources = m;
    }

    function open(entry) {
        Notifications.activate(entry);
        root.closeRequested();
    }

    SectionHeader {
        title: "Notifications"
        icon: "󰎟"

        // Count pill.
        Rectangle {
            visible: Notifications.count > 0
            implicitWidth: Math.max(20, countText.implicitWidth + Theme.spacing.small)
            implicitHeight: 20
            radius: height / 2
            color: Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g,
                           Theme.colors.accent.b, 0.22)

            Text {
                id: countText
                anchors.centerIn: parent
                text: Notifications.count
                font.family: Theme.font.main
                font.pointSize: Theme.dashboard.fontSmall
                color: Theme.colors.accent
            }
        }

        // Do Not Disturb.
        Rectangle {
            implicitWidth: 28
            implicitHeight: 28
            radius: height / 2
            color: Notifications.doNotDisturb ? Theme.colors.accent
                : dndMouse.containsMouse ? Theme.colors.surfaceVariant
                : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

            Text {
                anchors.centerIn: parent
                text: Notifications.doNotDisturb ? "󰂛" : "󰂚"
                font.family: Theme.font.icon
                font.pointSize: Theme.dashboard.fontMedium
                color: Notifications.doNotDisturb ? Theme.colors.bg : Theme.colors.textSecondary
            }

            MouseArea {
                id: dndMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.toggleDnd()
            }
        }

        // Clear all.
        Rectangle {
            visible: Notifications.count > 0
            implicitWidth: clearText.implicitWidth + Theme.spacing.normal * 2
            implicitHeight: 28
            radius: height / 2
            color: clearMouse.containsMouse ? Theme.colors.surfaceVariant
                : Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                          Theme.colors.surfaceVariant.b, 0.5)

            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

            Text {
                id: clearText
                anchors.centerIn: parent
                text: "Clear all"
                font.family: Theme.font.main
                font.pointSize: Theme.dashboard.fontSmall
                font.weight: Theme.font.mediumWeight
                color: Theme.colors.textPrimary
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.clear()
            }
        }
    }

    // Empty state — no ground of its own, just the line.
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        visible: Notifications.count === 0

        Text {
            anchors.centerIn: parent
            text: Notifications.doNotDisturb ? "Do Not Disturb is on" : "No notifications"
            font.family: Theme.font.main
            font.pointSize: Theme.dashboard.fontSmall
            color: Theme.colors.textTertiary
        }
    }

    // Flat history.
    Repeater {
        model: root.grouped ? [] : Notifications.list

        delegate: NotificationCard {
            required property var modelData
            required property int index
            Layout.fillWidth: true
            entry: modelData
            flat: true
            large: true
            showDivider: index < Notifications.list.length - 1
            onDismissRequested: Notifications.dismiss(modelData)
            onActivated: root.open(modelData)
        }
    }

    // One stack per source.
    Repeater {
        model: root.grouped ? root.groups : []

        delegate: NotificationGroup {
            required property var modelData
            Layout.fillWidth: true
            entries: modelData.entries
            expanded: root.expandedSources[modelData.appName] === true
            onToggleRequested: root.toggleSource(modelData.appName)
            onDismissRequested: entry => Notifications.dismiss(entry)
            onActivated: entry => root.open(entry)
        }
    }
}
