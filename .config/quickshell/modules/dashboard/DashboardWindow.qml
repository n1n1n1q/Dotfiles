import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.services.niri
import qs.modules.dashboard.components
import qs.modules.notifications
import qs.modules.settings

PanelWindow {
    id: root

    property bool shouldShow: false
    property var parentWindow: null
    property real barHeight: 50

    // Covers the whole output rather than just the card's own footprint, so a
    // plain click-outside MouseArea can dismiss it - niri has no equivalent
    // of Hyprland's HyprlandFocusGrab to grab focus/clicks compositor-side.
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    visible: shouldShow
    exclusiveZone: 0
    color: "transparent"

    // Never take keyboard focus - niri has nothing like Hyprland's
    // HyprlandFocusGrab, and grabbing focus here was stealing it from
    // whatever window was focused before the dashboard opened (and causing
    // flaky click-to-dismiss behavior in the process). Everything in this
    // window is mouse-driven, so it doesn't need focus at all.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function show() {
        shouldShow = true
    }
    function hide() {
        shouldShow = false
    }
    function toggle() {
        shouldShow = !shouldShow
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

        Rectangle {
            id: dashboard

            // Sits Theme.popup.margin off the frame on every side: the bar's
            // exclusive zone already drops this window's origin to just below
            // the bar, so `openY` is measured straight down from there, and
            // the height fills the rest of the screen minus the bottom
            // border + the same margin.
            readonly property real openY: Theme.popup.margin

            x: Theme.frame.thickness + Theme.popup.margin
            y: root.shouldShow ? openY : -height
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
                            width: 48
                            height: 48

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
                                text: "" // Font Awesome user icon
                                font.family: "Font Awesome 6 Free"
                                font.pixelSize: 24
                                color: Theme.colors.accent
                                visible: userIcon.status !== Image.Ready
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing.tiny

                            Text {
                                text: System.userName
                                font.pointSize: Theme.fontSize.large
                                font.weight: Font.Bold
                                color: Theme.colors.text
                            }

                            Text {
                                id: uptimeText
                                text: "Uptime: Loading..."
                                font.pointSize: Theme.fontSize.normal
                                color: Theme.colors.subtext0

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

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.colors.border
                    }

                    // Quick Toggles Row with background
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        color: Theme.colors.surface0
                        radius: Theme.rounding.medium

                        RowLayout {
                            anchors.centerIn: parent
                            width: parent.width - Theme.spacing.tiny * 2
                            height: parent.height - Theme.spacing.tiny * 2
                            spacing: 0

                            Repeater {
                                model: [
                                    {name: "WiFi", iconName: "wifi", active: WiFi.enabled, connected: WiFi.connected},
                                    {name: "Bluetooth", iconName: "bluetooth", active: Bluetooth.enabled, connected: Bluetooth.connected},
                                    {name: "Screenshot", iconName: "screenshot", active: false, connected: false},
                                    {name: "Lock", iconName: "lock", active: false, connected: false},
                                    {name: "Record", iconName: "record", active: false, connected: false},
                                    {name: "Settings", iconName: "settings", active: false, connected: false}
                                ]

                                Item {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 48

                                    QuickToggle {
                                        anchors.centerIn: parent
                                        width: 48
                                        height: 48

                                        name: modelData.name
                                        iconName: modelData.iconName
                                        active: modelData.active
                                        connected: modelData.connected ?? false

                                    onButtonClicked: {
                                        switch(modelData.name) {
                                            case "WiFi":
                                                WiFi.toggleWifi()
                                                break
                                            case "Bluetooth":
                                                Bluetooth.toggleBluetooth()
                                                break
                                            case "Screenshot":
                                                // niri ships its own interactive screenshot UI - no
                                                // grim/slurp/grimblast needed.
                                                NiriService.screenshot()
                                                root.hide()
                                                break
                                            case "Lock":
                                                Quickshell.execDetached(["swaylock"])
                                                root.hide()
                                                break
                                            case "Record":
                                                Quickshell.execDetached(["wf-recorder"])
                                                root.hide()
                                                break
                                            case "Settings":
                                                SettingsController.show()
                                                root.hide()
                                                break
                                        }
                                    }
                                    }
                                }
                            }
                        }
                    }

                    // Unified Sliders Section
                    GroupBox {
                        Layout.fillWidth: true
                        title: ""

                        background: Rectangle {
                            color: Theme.colors.surface0
                            radius: Theme.rounding.medium
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Theme.spacing.medium

                            // Volume Slider (expandable)
                            ExpandableSlider {
                                sliderIcon: Audio.muted ? "󰖁" : "󰕾"
                                sliderValue: Audio.volume
                                isMuted: Audio.muted
                                devices: Audio.sinks
                                currentDevice: Audio.sink

                                onValueChanged: Audio.setVolume(newValue)
                                onDeviceSelected: Audio.setAudioSink(device)
                            }

                            // Microphone Slider (expandable)
                            ExpandableSlider {
                                sliderIcon: Audio.sourceMuted ? "󰍭" : (Audio.sourceVolume > 0.5 ? "󰍬" : "󰍮")
                                sliderValue: Audio.sourceVolume
                                isMuted: Audio.sourceMuted
                                devices: Audio.sources
                                currentDevice: Audio.source

                                onValueChanged: Audio.setSourceVolume(newValue)
                                onDeviceSelected: Audio.setAudioSource(device)
                            }

                            // Brightness Slider (not expandable)
                            CompactSlider {
                                sliderIcon: Brightness.getBrightnessIcon()
                                sliderValue: Brightness.brightness
                                isMuted: false

                                onValueChanged: Brightness.setBrightness(newValue)
                            }
                        }
                    }

                    // Media Player (no background, no title)
                    MediaPlayer {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.colors.border
                    }

                    // Notification centre - full history, newest first.
                    NotificationCenter {
                        Layout.fillWidth: true
                        onCloseRequested: root.hide()
                    }

                    Item {
                        Layout.fillWidth: true
                        height: Theme.spacing.normal
                    }
                }
            }
        }
    }
}
