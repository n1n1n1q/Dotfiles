pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Transient toasts, top-right. One always-mapped click-through PanelWindow per
// screen (never toggle a layer-shell window's `visible` - niri remaps it at
// 0x0 on the 2nd show). The cards live in a non-interactive ListView and the
// window's input mask is the ListView's `contentItem`, so only the actual
// stack of cards catches clicks and the rest of the screen stays
// click-through (masking a bare `Column` positioner did NOT work - the close
// button was dead; masking `contentItem` is the pattern that does).
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:notifications"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: 0
            color: "transparent"
            visible: true

            // Full height, fixed width, hugging the right edge. The bar's
            // exclusive zone drops the top down to just under the bar.
            anchors {
                top: true
                right: true
                bottom: true
            }
            implicitWidth: Theme.popup.notifWidth
                + Theme.frame.thickness + Theme.popup.margin * 2

            mask: Region { item: listView.contentItem }

            ListView {
                id: listView

                anchors.fill: parent
                anchors.topMargin: Theme.popup.margin
                anchors.rightMargin: Theme.frame.thickness + Theme.popup.margin
                anchors.leftMargin: Theme.popup.margin

                spacing: Theme.spacing.normal
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
                        Notifications.dismissPopup(modelData)
                    }
                    onDismissRequested: Notifications.dismissPopup(modelData)
                    onActionInvoked: Notifications.dismissPopup(modelData)

                    Timer {
                        running: !toast.modelData.critical
                        interval: Theme.popup.notifTimeout
                        onTriggered: Notifications.dismissPopup(toast.modelData)
                    }
                }

                add: Transition {
                    NumberAnimation {
                        property: "opacity"; from: 0; to: 1
                        duration: Theme.animation.normal
                    }
                    NumberAnimation {
                        property: "x"; from: listView.width; to: 0
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
                        property: "x"; to: listView.width
                        duration: Theme.animation.normal; easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
