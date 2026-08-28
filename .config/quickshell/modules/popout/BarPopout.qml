import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// One always-mapped, click-through overlay per screen that hosts the bar's
// anchored dropdown cards. Follows Osd.qml's safety pattern rather than
// DashboardWindow's `visible` toggling: toggling a layer-shell window's
// `visible` rapidly leaves niri remapping it at 0x0. Instead the window stays
// mapped, its `mask` switches between empty (click-through) and full-screen
// (so a click outside the card dismisses it), and the card itself slides /
// fades.
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData

            // An empty screenName (e.g. from an IPC call, which can't know
            // which output) falls back to the first screen.
            readonly property bool active: PopoutController.current !== ""
                && (PopoutController.screenName === modelData.name
                    || (PopoutController.screenName === ""
                        && modelData.name === (Quickshell.screens[0]?.name ?? "")))

            // Remember the last non-empty card so it can animate out after the
            // controller clears `current` (Loader would otherwise unload it
            // instantly). Only swaps while a new card is actually requested.
            property string shownName: ""
            Connections {
                target: PopoutController
                function onCurrentChanged() {
                    if (PopoutController.current !== "")
                        win.shownName = PopoutController.current;
                }
            }

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell:popout"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: 0
            color: "transparent"
            visible: true

            // Full screen below the bar (the bar's exclusive zone drops the
            // origin), so a click anywhere outside the card can dismiss it.
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            // Empty when idle (click-through), full-window while a card is up.
            mask: Region {
                width: win.active ? win.width : 0
                height: win.active ? win.height : 0
            }

            // Click-outside-to-close scrim.
            MouseArea {
                anchors.fill: parent
                enabled: win.active
                onClicked: PopoutController.close()
            }

            Item {
                id: cardWrap

                readonly property real edge: Theme.frame.thickness + Theme.popup.margin
                readonly property real desiredX: PopoutController.anchorX - width / 2

                width: cardLoader.item ? cardLoader.item.implicitWidth : 0
                height: cardLoader.item ? cardLoader.item.implicitHeight : 0

                x: Math.max(edge, Math.min(desiredX, win.width - width - edge))
                y: win.active ? Theme.popup.margin : -height - 24
                opacity: win.active ? 1 : 0
                visible: opacity > 0.01

                Behavior on y {
                    NumberAnimation { duration: Theme.animation.normal; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.animation.normal; easing.type: Easing.OutCubic }
                }

                // Soft shadow, matching every other floating surface.
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -5
                    radius: Theme.popup.radius + 5
                    color: Theme.popup.shadow
                    z: -2
                }

                // Swallows clicks that miss the card's own controls so they
                // don't fall through to the dismiss scrim.
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onWheel: wheel => wheel.accepted = true
                }

                Loader {
                    id: cardLoader
                    anchors.centerIn: parent
                    sourceComponent: {
                        switch (win.shownName) {
                        case "calendar": return calendarComp;
                        case "media":    return mediaComp;
                        case "sysmon":   return sysmonComp;
                        default:         return null;
                        }
                    }
                }

                Component { id: calendarComp; CalendarCard {} }
                Component { id: mediaComp;    MediaCard {} }
                Component { id: sysmonComp;   SystemMonitorCard {} }
            }
        }
    }
}
