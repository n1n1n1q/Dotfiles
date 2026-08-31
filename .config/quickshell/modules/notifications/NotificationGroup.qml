import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// One source's notifications, collapsed into a stack. Collapsed it shows the
// newest card with the rest peeking out behind it and a count in the header;
// clicking the header drops the whole run down. A group of one is just the
// card, with no header at all.
//
// Only used when DashboardConfig.notifGrouping is "source" - the centre falls
// back to a flat list otherwise.
ColumnLayout {
    id: group

    required property var entries
    readonly property string appName: entries[0]?.appName ?? ""
    readonly property int count: entries.length
    readonly property bool stacked: count > 1

    // Controlled from the centre: a Repeater over a plain JS array rebuilds
    // every delegate whenever the notification list changes, so a flag kept in
    // here would snap the group shut the moment anything arrived or was
    // dismissed.
    property bool expanded: false

    // The centre owns what these mean, the same way it does for a flat card.
    signal activated(var entry)
    signal dismissRequested(var entry)
    signal toggleRequested()

    Layout.fillWidth: true
    spacing: Theme.spacing.tiny

    // --- header ----------------------------------------------------------
    // Wrapped in a plain Item so the click target can anchor over the whole
    // row - anchors on a layout's own child are undefined behaviour.
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacing.tiny
        Layout.rightMargin: Theme.spacing.tiny
        implicitHeight: headerRow.implicitHeight
        visible: group.stacked

        RowLayout {
            id: headerRow
            anchors.fill: parent
            spacing: Theme.spacing.small

            Image {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                visible: source.toString().length > 0 && status === Image.Ready
                source: Notifications.iconSource(group.entries[0])
                sourceSize.width: 32
                sourceSize.height: 32
                asynchronous: true
            }

            Text {
                text: group.appName
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                font.weight: Theme.font.semiBold
                color: Theme.colors.textSecondary
            }

            Rectangle {
                implicitWidth: countText.implicitWidth + Theme.spacing.small
                implicitHeight: 16
                radius: 8
                color: Theme.colors.surfaceVariant

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: group.count
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.tiny
                    color: Theme.colors.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: group.expanded ? "Show less" : "Show all"
                font.family: Theme.font.main
                font.pointSize: Theme.font.tiny
                color: headMouse.containsMouse ? Theme.colors.accent : Theme.colors.textTertiary
            }

            Text {
                text: group.expanded ? "󰅃" : "󰅀"
                font.family: Theme.font.icon
                font.pointSize: Theme.font.small
                color: headMouse.containsMouse ? Theme.colors.accent : Theme.colors.textTertiary
            }
        }

        MouseArea {
            id: headMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: group.toggleRequested()
        }
    }

    // --- the stack -------------------------------------------------------
    // Collapsed, only the newest card is real; the two slivers behind it are
    // decoration standing in for the rest of the run.
    Item {
        Layout.fillWidth: true
        implicitHeight: topCard.implicitHeight
            + (group.stacked && !group.expanded ? 8 : 0)

        Rectangle {
            visible: group.stacked && !group.expanded
            anchors.horizontalCenter: parent.horizontalCenter
            y: topCard.height - 10
            width: parent.width - 26
            height: 12
            radius: Theme.rounding.medium
            color: Theme.colors.surfaceVariant
        }

        Rectangle {
            visible: group.stacked && !group.expanded && group.count > 2
            anchors.horizontalCenter: parent.horizontalCenter
            y: topCard.height - 6
            width: parent.width - 48
            height: 12
            radius: Theme.rounding.medium
            color: Theme.colors.surfaceVariant
            opacity: 0.6
        }

        NotificationCard {
            id: topCard
            width: parent.width
            entry: group.entries[0]
            onActivated: group.activated(group.entries[0])
            onDismissRequested: group.dismissRequested(group.entries[0])
        }
    }

    // The rest of the run, revealed by the header.
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacing.normal
        spacing: 0
        visible: group.expanded && group.stacked

        Repeater {
            model: group.expanded ? group.entries.slice(1) : []

            delegate: NotificationCard {
                required property var modelData
                Layout.fillWidth: true
                entry: modelData
                onActivated: group.activated(modelData)
                onDismissRequested: group.dismissRequested(modelData)
            }
        }
    }
}
