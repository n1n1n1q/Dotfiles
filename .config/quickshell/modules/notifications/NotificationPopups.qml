pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Transient toasts in the screen corner set by DashboardConfig.notifCorner.
// One always-mapped click-through PanelWindow per screen (never toggle a
// layer-shell window's `visible` - niri remaps it at 0x0 on the 2nd show). The
// cards live in a non-interactive ListView and the window's input mask is the
// ListView's `contentItem`, so only the actual stack of cards catches clicks
// and the rest of the screen stays click-through (masking a bare `Column`
// positioner did NOT work - the close button was dead; masking `contentItem`
// is the pattern that does).
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData

            readonly property bool atTop: DashboardConfig.notifAtTop
            readonly property bool atLeft: DashboardConfig.notifAtLeft

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:notifications"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: 0
            color: "transparent"
            visible: true

            // Full height, fixed width, hugging the chosen side. The bar's
            // exclusive zone drops the top down to just under the bar; the
            // stack itself grows away from the anchored corner.
            anchors {
                top: true
                bottom: true
                left: win.atLeft
                right: !win.atLeft
            }
            implicitWidth: Theme.popup.notifWidth
                + Theme.frame.thickness + Theme.popup.margin * 2

            mask: Region { item: listView.contentItem }

            ListView {
                id: listView

                anchors.fill: parent
                anchors.topMargin: Theme.popup.margin
                anchors.bottomMargin: Theme.frame.thickness + Theme.popup.margin
                anchors.leftMargin: win.atLeft
                    ? Theme.frame.thickness + Theme.popup.margin : Theme.popup.margin
                anchors.rightMargin: win.atLeft
                    ? Theme.popup.margin : Theme.frame.thickness + Theme.popup.margin

                // Bottom corners stack upwards, so the newest toast is always
                // the one nearest the corner it comes out of.
                verticalLayoutDirection: win.atTop
                    ? ListView.TopToBottom : ListView.BottomToTop

                // The card keeps a transparent gutter for its overhanging close
                // button, which already reads as most of the gap between cards.
                spacing: Theme.spacing.tiny
                interactive: false
                // Keep every delegate realised even past the screen edge so
                // their auto-dismiss timers keep running.
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

                // Toasts slide in from - and back out towards - whichever side
                // of the screen they're anchored to.
                readonly property real offX: win.atLeft ? -width : width

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
    }
}
