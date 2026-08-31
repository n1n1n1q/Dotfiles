import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.modules.dashboard.components
import qs.modules.notifications
import qs.modules.osd
import qs.modules.settings

PanelWindow {
    id: root

    property bool shouldShow: false
    property var parentWindow: null
    property real barHeight: 50

    // Editing the panel's layout pins it open — you're arranging the thing you
    // are looking at, and a stray click outside must not close it mid-drag.
    readonly property bool editing: DashboardConfig.editMode
    readonly property bool open: shouldShow || editing

    // Covers the whole output rather than just the card's own footprint, so a
    // plain click-outside MouseArea can dismiss it - niri has no equivalent
    // of Hyprland's HyprlandFocusGrab to grab focus/clicks compositor-side.
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    visible: open
    exclusiveZone: 0
    color: "transparent"

    // Never take keyboard focus while it's just open - niri has nothing like
    // Hyprland's HyprlandFocusGrab, and grabbing focus here was stealing it
    // from whatever window was focused before the dashboard opened (and
    // causing flaky click-to-dismiss behavior in the process). Everything in
    // the panel is mouse-driven, so it doesn't need focus at all.
    //
    // Layout editing is the exception: it's a deliberate modal session that
    // ends on Enter / Esc, the same as the bar editor's overlay.
    WlrLayershell.keyboardFocus: editing
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // The dashboard's own sliders show the volume / brightness level as you
    // drag them, so hold the OSD inhibit while it's open - otherwise every
    // drag also drops the OSD pill under the bar, saying the same thing.
    onOpenChanged: open ? OsdController.inhibit() : OsdController.release()
    Component.onDestruction: {
        if (open)
            OsdController.release()
    }

    function show() {
        shouldShow = true
    }
    function hide() {
        if (editing)
            return
        shouldShow = false
    }
    function toggle() {
        if (editing)
            return
        shouldShow = !shouldShow
    }

    // Driven by the bar's window-title widget and by
    // `qs ipc call dashboard open|hide|toggle`. An empty screen name is a
    // broadcast; anything else has to match this panel's own output.
    function _addressed(screenName) {
        return screenName.length === 0 || screenName === (root.screen?.name ?? "")
    }

    Connections {
        target: DashboardConfig
        function onShowRequested(screenName) { if (root._addressed(screenName)) root.show() }
        function onHideRequested(screenName) { if (root._addressed(screenName)) root.hide() }
        function onToggleRequested(screenName) { if (root._addressed(screenName)) root.toggle() }
    }

    // Don't leave a session stuck open if Settings is closed with the edit
    // toggle still on - the same guard BarEditOverlay keeps.
    Connections {
        target: SettingsController
        function onOpenChanged() {
            if (!SettingsController.open && DashboardConfig.editMode)
                DashboardConfig.commitEdit();
        }
    }

    Item {
        anchors.fill: parent

        // Click-outside-to-close scrim. Plain Rectangles don't consume mouse
        // events on their own, so this MouseArea filling the whole output is
        // what a click anywhere outside the card actually hits.
        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }

        // Faint dim behind the card while editing, so the panel reads as modal
        // the same way the bar editor does.
        Rectangle {
            anchors.fill: parent
            visible: root.editing
            color: Qt.rgba(0, 0, 0, 0.25)
        }

        // Enter saves, Esc drops a held tile and then ends the session.
        Item {
            anchors.fill: parent
            focus: root.editing
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape) {
                    if (DashboardConfig.grabbing) DashboardConfig.cancelGrab();
                    else DashboardConfig.cancelEdit();
                    e.accepted = true;
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    DashboardConfig.commitEdit();
                    e.accepted = true;
                }
            }
        }

        Rectangle {
            id: dashboard

            // Sits Theme.popup.margin off the frame on every side: the bar's
            // exclusive zone already drops this window's origin to just below
            // the bar, so `openY` is measured straight down from there, and
            // the height fills the rest of the screen minus the bottom
            // border + the same margin.
            readonly property real openY: Theme.popup.margin

            x: Theme.frame.thickness + Theme.popup.margin
            y: root.open ? openY : -height
            width: Theme.sizes.dashboardWidth
            height: root.height - openY - Theme.frame.thickness - Theme.popup.margin

            color: Theme.popup.background
            radius: Theme.popup.radius
            border.color: Theme.popup.border
            border.width: Theme.popup.borderWidth

            Behavior on y {
                NumberAnimation {
                    duration: 200  // Faster, smoother animation
                    easing.type: Easing.OutCubic
                }
            }

            // Swallows clicks so they don't fall through to the scrim behind.
            MouseArea {
                anchors.fill: parent
            }

            // Drop shadow only - removed border glow
            Rectangle {
                anchors.fill: parent
                anchors.margins: -5
                radius: parent.radius + 5
                color: Theme.popup.shadow
                z: -2
            }

            clip: true

            ScrollView {
                anchors.fill: parent
                anchors.margins: Theme.padding.xlarge
                clip: true

                ColumnLayout {
                    width: dashboard.width - Theme.padding.xlarge * 2
                    spacing: Theme.spacing.large

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.medium

                        // User icon and info
                        Item {
                            width: 40
                            height: 40

                            Image {
                                id: userIcon
                                visible: false
                                source: "file://" + System.userIconPath
                                sourceSize.width: 96
                                sourceSize.height: 96
                                smooth: true
                                asynchronous: true
                                cache: false
                                onStatusChanged: if (status === Image.Ready) userIconCanvas.requestPaint()
                            }

                            // Background circle
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: width / 2
                                color: Theme.colors.surface0
                                antialiasing: true
                            }

                            // Circular canvas mask for image
                            Canvas {
                                id: userIconCanvas
                                anchors.fill: parent
                                anchors.margins: 2
                                antialiasing: true
                                visible: userIcon.status === Image.Ready

                                onPaint: {
                                    if (userIcon.status !== Image.Ready) return

                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.save()

                                    // Create circular clipping path
                                    ctx.beginPath()
                                    ctx.arc(width / 2, height / 2, width / 2, 0, Math.PI * 2, false)
                                    ctx.closePath()
                                    ctx.clip()

                                    // Draw the image
                                    ctx.drawImage(userIcon, 0, 0, width, height)
                                    ctx.restore()
                                }
                            }

                            // Border circle
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: "transparent"
                                border.color: Theme.colors.accent
                                border.width: 2
                                antialiasing: true
                            }

                            // Fallback icon when image is not available
                            Text {
                                anchors.centerIn: parent
                                text: "󰀄" // nf-md-account
                                font.family: Theme.font.icon
                                font.pointSize: Theme.font.xlarge
                                color: Theme.colors.accent
                                visible: userIcon.status !== Image.Ready
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: System.userName
                                font.family: Theme.font.main
                                font.pointSize: Theme.font.large
                                font.weight: Theme.font.mediumWeight
                                color: Theme.colors.textPrimary
                            }

                            Text {
                                id: uptimeText
                                text: "Uptime: Loading..."
                                font.family: Theme.font.main
                                font.pointSize: Theme.font.small
                                color: Theme.colors.textTertiary

                                Timer {
                                    interval: 60000
                                    running: true
                                    repeat: true
                                    triggeredOnStart: true
                                    onTriggered: {
                                        const now = new Date()
                                        const hours = now.getHours()
                                        const minutes = now.getMinutes()
                                        uptimeText.text = `Uptime: ${hours}h ${minutes}m`
                                    }
                                }
                            }
                        }
                    }

                    // Quick settings — a configurable grid of one- and two-cell
                    // tiles (Settings > Dashboard, or `qs ipc call dashboard edit`).
                    QuickSettingsGrid {
                        Layout.fillWidth: true
                        ghost: dragGhost
                        onCloseRequested: root.hide()
                    }

                    // Sliders — configurable the same way; right-click one for
                    // its device list.
                    SliderStack {
                        Layout.fillWidth: true
                        ghost: dragGhost
                    }

                    // Notification centre - full history, newest first.
                    NotificationCenter {
                        Layout.fillWidth: true
                        visible: !root.editing
                        onCloseRequested: root.hide()
                    }

                    DashboardEditDock {
                        Layout.fillWidth: true
                        visible: root.editing
                        ghost: dragGhost
                    }

                    Item {
                        Layout.fillWidth: true
                        height: Theme.spacing.normal
                    }
                }
            }
        }

        // The drag ghost floats above the card (and above the ScrollView that
        // the tiles were picked up in), so it lives at the top of the window.
        DragProxy {
            id: dragGhost
        }
    }
}
