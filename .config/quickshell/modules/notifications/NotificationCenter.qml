import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// Notification centre for the dashboard: the full `Notifications.list` history,
// newest first, each row a NotificationCard whose close button drops it from
// the centre. Sits inside the dashboard's own ScrollView, so it just grows -
// no nested scrolling.
ColumnLayout {
    id: root
    spacing: Theme.spacing.small

    // Emitted when a notification is clicked through to its app - the
    // dashboard should get out of the way.
    signal closeRequested()

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.small

        Text {
            text: "Notifications"
            font.family: Theme.font.main
            font.pointSize: Theme.fontSize.large
            font.weight: Font.Bold
            color: Theme.colors.text
        }

        Text {
            visible: Notifications.count > 0
            text: Notifications.count
            font.family: Theme.font.main
            font.pointSize: Theme.fontSize.small
            color: Theme.colors.textTertiary
        }

        Item { Layout.fillWidth: true }

        // Do Not Disturb
        Text {
            text: Notifications.doNotDisturb ? "󰂛" : "󰂚"
            font.family: Theme.font.icon
            font.pointSize: Theme.fontSize.large
            color: Notifications.doNotDisturb
                ? Theme.colors.accent : dndMouse.containsMouse
                    ? Theme.colors.textPrimary : Theme.colors.textTertiary

            MouseArea {
                id: dndMouse
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.toggleDnd()
            }
        }

        Text {
            visible: Notifications.count > 0
            text: "Clear all"
            font.family: Theme.font.main
            font.pointSize: Theme.fontSize.small
            color: clearMouse.containsMouse
                ? Theme.colors.accent : Theme.colors.textSecondary

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.clear()
            }
        }
    }

    // Empty state
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 72
        visible: Notifications.count === 0
        radius: Theme.rounding.medium
        color: Theme.colors.surface0

        Text {
            anchors.centerIn: parent
            text: Notifications.doNotDisturb ? "Do Not Disturb is on" : "No notifications"
            font.family: Theme.font.main
            font.pointSize: Theme.fontSize.small
            color: Theme.colors.textTertiary
        }
    }

    Repeater {
        model: Notifications.list

        delegate: NotificationCard {
            required property var modelData
            Layout.fillWidth: true
            entry: modelData
            onDismissRequested: Notifications.dismiss(modelData)
            onActivated: {
                Notifications.activate(modelData)
                root.closeRequested()
            }
        }
    }
}
