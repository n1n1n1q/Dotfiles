import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import "dashboard"

PanelWindow {
    id: root
    
    property bool shouldShow: false
    property var parentWindow: null
    property real barHeight: 50
    
    anchors {
        top: true
        left: true
    }
    
    implicitWidth: Theme.sizes.dashboardWidth
    implicitHeight: shouldShow ? Theme.sizes.dashboardHeight : 0
    margins {
        left: Theme.spacing.large - 10
        top: barHeight - Theme.spacing.xlarge - Theme.spacing.tiny - 12
    }
    
    visible: shouldShow
    exclusiveZone: 0
    color: "transparent"
    
    // Enable keyboard focus and focus grab for unfocus-to-close behavior
    WlrLayershell.keyboardFocus: shouldShow ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    function show() { 
        console.log("Dashboard show() called")
        shouldShow = true
    }
    function hide() { 
        console.log("Dashboard hide() called")
        shouldShow = false 
    }
    function toggle() { 
        console.log("Dashboard toggle() called, current shouldShow:", shouldShow)
        shouldShow = !shouldShow
        if (shouldShow) {
            Qt.callLater(() => root.forceActiveFocus())
        }
    }
    
    // Focus grab to close on unfocus
    HyprlandFocusGrab {
        active: root.shouldShow
        windows: [root]
        onCleared: root.hide()
    }
    
    FocusScope {
        anchors.fill: parent
        focus: root.shouldShow
        
        Keys.onPressed: (event) => {
            root.hide()
            event.accepted = true
        }
        
        Rectangle {
            id: dashboard
            
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            
            // Use y position for slide animation instead of height
            y: root.shouldShow ? 0 : -height
            height: Theme.sizes.dashboardHeight
            
            color: Theme.colors.background
            radius: Theme.rounding.xlarge
            border.color: Theme.colors.border
            border.width: 1
            
            Behavior on y {
                NumberAnimation {
                    duration: 200  // Faster, smoother animation
                    easing.type: Easing.OutCubic
                }
            }
        
        // Drop shadow only - removed border glow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -5
            radius: parent.radius + 5
            color: "#00000060"
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
                            text: "\uf007" // Font Awesome user icon
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
                                            Hyprland.dispatch("exec", "grimblast copy area")
                                            root.hide()
                                            break
                                        case "Lock":
                                            Hyprland.dispatch("exec", "hyprlock")
                                            root.hide()
                                            break
                                        case "Record":
                                            Hyprland.dispatch("exec", "wf-recorder")
                                            root.hide()
                                            break
                                        case "Settings":
                                            Hyprland.dispatch("exec", "gnome-control-center")
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
                            sliderIcon: Audio.muted ? "\udb81\udd81" : "\udb81\udd7e"
                            sliderValue: Audio.volume
                            isMuted: Audio.muted
                            devices: Audio.sinks
                            currentDevice: Audio.sink
                            
                            onValueChanged: Audio.setVolume(newValue)
                            onDeviceSelected: Audio.setAudioSink(device)
                        }
                        
                        // Microphone Slider (expandable)
                        ExpandableSlider {
                            sliderIcon: Audio.sourceMuted ? "\udb80\udf6d" : (Audio.sourceVolume > 0.5 ? "\udb80\udf6c" : "󰍮")
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
                
                Item {
                    Layout.fillWidth: true
                    height: Theme.spacing.normal
                }
            }
        }
        }
    }
}
