import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Notification centre for the dashboard: the full `Notifications.list` history,
// newest first. With DashboardConfig.notifGrouping off that's one card per
// notification (the default); "source" collapses each app into its own stack.
//
// The header (title + "Clear all") is pinned; only the list below it scrolls,
// so a burst of notifications never stretches the whole dashboard — it just
// fills this panel and scrolls within it.
//
// The flat list is a ScriptModel over the live NotifItem objects — adding or
// removing one is an incremental update, so a card that is mid-swipe-out is
// never rebuilt out from under its animation.
ColumnLayout {
    id: root
    spacing: Theme.spacing.small

    // Emitted when a notification is clicked through to its app — the dashboard
    // should get out of the way.
    signal closeRequested()

    readonly property bool grouped: DashboardConfig.notifGrouped

    // [{ appName, entries }] in the order each source last spoke, closed
    // entries filtered out. Recomputed imperatively off listChanged rather than
    // as a bound expression — a `property var` that allocates a fresh array on
    // every read tends to trip Qt's binding-loop guard when the views that
    // consume it also read Notifications.list.
    property var groups: []

    function _recomputeGroups() {
        if (!grouped) {
            if (root.groups.length > 0)
                root.groups = [];
            return;
        }
        const byApp = {};
        const out = [];
        for (const e of Notifications.list) {
            if (e.closed)
                continue;
            const key = e.appName || "Notification";
            if (byApp[key] === undefined) {
                byApp[key] = { appName: key, entries: [] };
                out.push(byApp[key]);
            }
            byApp[key].entries.push(e);
        }
        root.groups = out;
    }

    onGroupedChanged: _recomputeGroups()
    Component.onCompleted: _recomputeGroups()

    Connections {
        target: Notifications
        function onListChanged() { root._recomputeGroups() }
    }

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

    // --- header ---------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: Theme.spacing.tiny
        spacing: Theme.spacing.small

        Text {
            text: "󰎟"
            font.family: Theme.font.icon
            font.pointSize: Theme.dashboard.fontMedium
            color: Theme.colors.textSecondary
        }

        Text {
            text: "Notifications"
            font.family: Theme.font.main
            font.pointSize: Theme.dashboard.fontMedium
            font.weight: Theme.font.semiBold
            color: Theme.colors.textSecondary
        }

        Item { Layout.fillWidth: true }

        // The only control in the header now — dimmed and inert when there is
        // nothing to clear.
        Rectangle {
            readonly property bool on: Notifications.count > 0
            implicitWidth: clearText.implicitWidth + Theme.spacing.normal * 2
            implicitHeight: 28
            radius: height / 2
            color: !on ? "transparent"
                : clearMouse.containsMouse ? Theme.colors.accentTintStrong
                : Theme.colors.accentTint

            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

            Text {
                id: clearText
                anchors.centerIn: parent
                text: "Clear all"
                font.family: Theme.font.main
                font.pointSize: Theme.dashboard.fontSmall
                font.weight: Theme.font.mediumWeight
                color: parent.on ? Theme.colors.accent : Theme.colors.textTertiary

                Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                enabled: parent.on
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.clearAll()
            }
        }
    }

    // --- empty state ---------------------------------------------------
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: Notifications.count === 0

        Text {
            anchors.centerIn: parent
            text: Notifications.doNotDisturb ? "Do Not Disturb is on" : "No notifications"
            font.family: Theme.font.main
            font.pointSize: Theme.dashboard.fontSmall
            color: Theme.colors.textTertiary
        }
    }

    // --- scrolling history --------------------------------------------
    ScrollView {
        id: scroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: Notifications.count > 0
        clip: true
        contentWidth: availableWidth

        // Reserve the scrollbar's width — the Basic-style bar keeps an
        // interactive hit-strip at 0 opacity that otherwise eats the cards'
        // swipe-to-delete clicks near the right edge.
        rightPadding: vBar.width + Theme.spacing.tiny
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical: ScrollBar {
            id: vBar
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            width: scroll.availableWidth
            spacing: Theme.spacing.tiny

            // --- flat history ------------------------------------------
            Repeater {
                model: ScriptModel {
                    values: root.grouped ? [] : Notifications.list
                }

                delegate: NotificationCard {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    entry: modelData
                    flat: true
                    large: true
                    showDivider: index < Notifications.count - 1
                    onDismissRequested: modelData.close()
                    onActivated: root.open(modelData)
                }
            }

            // --- one stack per source --------------------------------
            Repeater {
                model: root.grouped ? root.groups : []

                delegate: NotificationGroup {
                    required property var modelData
                    Layout.fillWidth: true
                    entries: modelData.entries
                    expanded: root.expandedSources[modelData.appName] === true
                    onToggleRequested: root.toggleSource(modelData.appName)
                    onDismissRequested: entry => entry.close()
                    onActivated: entry => root.open(entry)
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
