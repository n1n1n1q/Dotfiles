import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.widgets

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

            // Remember the last non-empty card (+ its payload) so it can
            // animate out after the controller clears `current` (Loader would
            // otherwise unload it instantly). Only swaps while a new card is
            // actually requested.
            property string shownName: ""
            property var shownPayload: null
            Connections {
                target: PopoutController
                function onCurrentChanged() {
                    if (PopoutController.current !== "") {
                        win.shownName = PopoutController.current;
                        win.shownPayload = PopoutController.payload;
                    }
                }
                // A switch between two of the same card kind (e.g. right-click a
                // different tray icon) leaves `current` unchanged — pick up the
                // new payload here.
                function onPayloadChanged() {
                    if (PopoutController.current !== "")
                        win.shownPayload = PopoutController.payload;
                }
            }

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell:popout"
            // OnDemand, not Exclusive: a light dropdown shouldn't yank keyboard
            // focus off whatever window you were in (that also made a second
            // right-click on another tray icon feel dead). Escape still closes
            // it once the card itself has been clicked/focused.
            WlrLayershell.keyboardFocus: win.active
                ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
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

            Item {
                anchors.fill: parent
                focus: win.active
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Escape) {
                        PopoutController.close();
                        e.accepted = true;
                    }
                }
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

                SoftShadow { radius: Theme.popup.radius }

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
                        case "traymenu": return traymenuComp;
                        default:         return null;
                        }
                    }
                }

                Component { id: calendarComp; CalendarCard {} }
                Component { id: mediaComp;    MediaCard {} }
                Component { id: sysmonComp;   SystemMonitorCard {} }
                Component { id: traymenuComp; TrayMenuCard { item: win.shownPayload } }
            }
        }
    }
}
