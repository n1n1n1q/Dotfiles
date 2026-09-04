pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.modules.notifications

// Transient toast stack for one screen, hugging the corner set by
// DashboardConfig.notifCorner. Hosted by the Drawers window; the cards live in
// a non-interactive ListView and `listContent` is exported so the host can mask
// just that stack for input. Was the PanelWindow body of NotificationPopups.qml.
Item {
    id: root

    readonly property bool atTop: DashboardConfig.notifAtTop
    readonly property bool atLeft: DashboardConfig.notifAtLeft

    // Inset past the bar on whichever edge it's docked (toasts only ever anchor
    // a screen corner, so only the top/bottom docked bar matters here).
    readonly property real barTop: (BarConfig.edge === "top" && !BarConfig.floating) ? Theme.bar.height : 0
    readonly property real barBottom: (BarConfig.edge === "bottom" && !BarConfig.floating) ? Theme.bar.height : 0

    readonly property alias listContent: listView.contentItem

    width: Theme.popup.notifWidth + Theme.frame.thickness + Theme.popup.margin * 2
    anchors {
        top: parent.top
        bottom: parent.bottom
        left: root.atLeft ? parent.left : undefined
        right: root.atLeft ? undefined : parent.right
    }

    ListView {
        id: listView

        anchors.fill: parent
        anchors.topMargin: root.barTop + Theme.popup.margin
        anchors.bottomMargin: root.barBottom + Theme.frame.thickness + Theme.popup.margin
        anchors.leftMargin: root.atLeft
            ? Theme.frame.thickness + Theme.popup.margin : Theme.popup.margin
        anchors.rightMargin: root.atLeft
            ? Theme.popup.margin : Theme.frame.thickness + Theme.popup.margin

        verticalLayoutDirection: root.atTop
            ? ListView.TopToBottom : ListView.BottomToTop

        spacing: Theme.spacing.tiny
        interactive: false
        cacheBuffer: 100000

        model: ScriptModel { values: Notifications.popups }

        delegate: NotificationCard {
            id: toast
            required property var modelData

            width: ListView.view.width
            entry: modelData

            onActivated: {
                Notifications.activate(modelData)
                modelData.dropPopup()
            }
            onDismissRequested: modelData.dropPopup()
            onActionInvoked: modelData.dropPopup()

            Timer {
                running: !toast.modelData.critical
                interval: Theme.popup.notifTimeout
                onTriggered: toast.modelData.dropPopup()
            }
        }

        readonly property real offX: root.atLeft ? -width : width

        add: Transition {
            NumberAnimation {
                property: "opacity"; from: 0; to: 1
                duration: Theme.animation.normal
            }
            NumberAnimation {
                property: "x"; from: listView.offX; to: 0
                duration: Theme.animation.normal; easing.type: Easing.OutCubic
            }
        }
        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: Theme.animation.normal; easing.type: Easing.OutCubic
            }
        }
        remove: Transition {
            NumberAnimation {
                property: "opacity"; to: 0
                duration: Theme.animation.fast
            }
            NumberAnimation {
                property: "x"; to: listView.offX
                duration: Theme.animation.normal; easing.type: Easing.OutCubic
            }
        }
    }
}
