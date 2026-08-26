import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import qs.services

ApplicationWindow {
    id: settingsWindow
    
    width: 800
    height: 600
    title: "QuickShell Settings"
    flags: Qt.Window | Qt.WindowStaysOnTopHint
    
    // Center the window on screen
    Component.onCompleted: {
        x = (Screen.width - width) / 2
        y = (Screen.height - height) / 2
    }
    
    color: "#1e1e2e"
    
    // Header bar with title and close button
    Rectangle {
        id: headerBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right:                            Button {
                                text: "\uf00d Quit QuickShell"
                                onClicked: Qt.quit()
                                
                                background: Rectangle {
                                    color: parent.pressed ? "#a6adc8" : (parent.hovered ? "#f38ba8" : "#45475a")
                                    radius: 6
                                }
                                
                                contentItem: Text {
                                    text: parent.text
                                    color: "#1e1e2e"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pointSize: 10
                                    font.bold: true
                                }
                            }    height: 60
        color: "#313244"
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            
            Text {
                text: "\uf013 QuickShell Configuration"
                font.family: "Symbols Nerd Font"
                font.pointSize: 18
                font.bold: true
                color: "#cdd6f4"
                Layout.fillWidth: true
            }
            
            Button {
                text: "\uf00d"
                font.family: "Symbols Nerd Font"
                width: 40
                height: 40
                font.pointSize: 16
                font.bold: true
                
                onClicked: settingsWindow.close()
                
                background: Rectangle {
                    color: parent.pressed ? "#f38ba8" : (parent.hovered ? "#eba0ac" : "transparent")
                    radius: 6
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "#cdd6f4"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
    
    // Main content area
    RowLayout {
        anchors.top: headerBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 0
        spacing: 0
        
        // Sidebar navigation
        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            color: "#181825"
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 5
                
                Text {
                    text: "Categories"
                    font.pointSize: 12
                    font.bold: true
                    color: "#89b4fa"
                    Layout.bottomMargin: 10
                }
                
                Repeater {
                    model: [
                        {name: "Audio", icon: "", page: "audio"},
                        {name: "Display", icon: "", page: "display"},
                        {name: "Workspaces", icon: "", page: "workspaces"},
                        {name: "Appearance", icon: "", page: "appearance"},
                        {name: "System", icon: "", page: "system"},
                        {name: "About", icon: "", page: "about"}
                    ]
                    
                    Button {
                        Layout.fillWidth: true
                        height: 40
                        
                        property bool isSelected: contentArea.currentPage === modelData.page
                        
                        onClicked: contentArea.currentPage = modelData.page
                        
                        background: Rectangle {
                            color: parent.isSelected ? "#89b4fa" : 
                                   (parent.pressed ? "#313244" : 
                                   (parent.hovered ? "#45475a" : "transparent"))
                            radius: 6
                        }
                        
                        contentItem: RowLayout {
                            spacing: 10
                            
                            Text {
                                text: modelData.icon
                                font.family: "Symbols Nerd Font"
                                font.pointSize: 14
                                color: parent.parent.isSelected ? "#1e1e2e" : "#cdd6f4"
                            }
                            
                            Text {
                                text: modelData.name
                                font.pointSize: 11
                                color: parent.parent.isSelected ? "#1e1e2e" : "#cdd6f4"
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
                
                Item { Layout.fillHeight: true }
            }
        }
        
        // Vertical separator
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: "#313244"
        }
        
        // Content area
        StackLayout {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            property string currentPage: "audio"
            currentIndex: {
                switch(currentPage) {
                    case "audio": return 0
                    case "display": return 1
                    case "workspaces": return 2
                    case "appearance": return 3
                    case "system": return 4
                    case "about": return 5
                    default: return 0
                }
            }
            
            // Audio Settings Page
            ScrollView {
                clip: true
                
                ColumnLayout {
                    width: parent.width
                    anchors.margins: 30
                    spacing: 20
                    
                    Text {
                        text: "\udb81\udd7e Audio Settings"
                        font.family: "Symbols Nerd Font"
                        font.pointSize: 20
                        font.bold: true
                        color: "#cdd6f4"
                        Layout.bottomMargin: 10
                    }
                    
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Volume Control"
                        
                        background: Rectangle {
                            color: "#313244"
                            radius: 8
                            border.color: "#45475a"
                            border.width: 1
                        }
                        
                        label: Text {
                            text: parent.title
                            color: "#89b4fa"
                            font.bold: true
                            font.pointSize: 12
                        }
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 15
                            
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 15
                                
                                Text {
                                    text: "Master Volume:"
                                    color: "#cdd6f4"
                                    font.pointSize: 11
                                }
                                
                                Slider {
                                    Layout.fillWidth: true
                                    from: 0
                                    to: 1
                                    value: Audio.volume
                                    
                                    onValueChanged: Audio.setVolume(value)
                                    
                                    background: Rectangle {
                                        x: parent.leftPadding
                                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                        width: parent.availableWidth
                                        height: 6
                                        radius: 3
                                        color: "#45475a"
                                        
                                        Rectangle {
                                            width: parent.parent.visualPosition * parent.width
                                            height: parent.height
                                            color: "#89b4fa"
                                            radius: 3
                                        }
                                    }
                                    
                                    handle: Rectangle {
                                        x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                                        y: parent.topPadding + parent.availableHeight / 2 - height / 2
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: parent.pressed ? "#74c7ec" : "#89b4fa"
                                        border.color: "#cdd6f4"
                                        border.width: 2
                                    }
                                }
                                
                                Text {
                                    text: Math.round(Audio.volume * 100) + "%"
                                    color: "#cdd6f4"
                                    font.pointSize: 11
                                    font.bold: true
                                    Layout.minimumWidth: 45
                                }
                            }
                            
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                
                                Button {
                                    text: Audio.muted ? "\udb81\udd81 Unmute" : "\udb81\udd7e Mute"
                                    font.family: "Symbols Nerd Font"
                                    onClicked: Audio.toggleMute()
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#f38ba8" : (parent.hovered ? "#eba0ac" : "#45475a")
                                        radius: 8
                                    }
                                    
                                    contentItem: Text {
                                        text: parent.text
                                        font.family: "Symbols Nerd Font"
                                        color: "#cdd6f4"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pointSize: 11
                                    }
                                }
                                
                                Item { Layout.fillWidth: true }
                                
                                Text {
                                    text: "Device: " + (Audio.sinkExists ? "Connected" : "Not Available")
                                    color: Audio.sinkExists ? "#a6e3a1" : "#f38ba8"
                                    font.pointSize: 10
                                }
                            }
                        }
                    }
                }
            }
            
            // Display Settings Page
            ScrollView {
                clip: true
                
                ColumnLayout {
                    width: parent.width
                    anchors.margins: 30
                    spacing: 20
                    
                    Text {
                        text: "\uf108 Display Settings"
                        font.family: "Symbols Nerd Font"
                        font.pointSize: 20
                        font.bold: true
                        color: "#cdd6f4"
                        Layout.bottomMargin: 10
                    }
                    
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Screen Information"
                        
                        background: Rectangle {
                            color: "#313244"
                            radius: 8
                            border.color: "#45475a"
                            border.width: 1
                        }
                        
                        label: Text {
                            text: parent.title
                            color: "#89b4fa"
                            font.bold: true
                            font.pointSize: 12
                        }
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10
                            
                            Text {
                                text: "Display Configuration"
                                color: "#cdd6f4"
                                font.pointSize: 11
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 60
                                color: "#45475a"
                                radius: 6
                                
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    
                                    Text {
                                        text: "Primary Display"
                                        color: "#cdd6f4"
                                        font.pointSize: 11
                                        font.bold: true
                                    }
                                    
                                    Text {
                                        text: "Hyprland Wayland Session"
                                        color: "#a6adc8"
                                        font.pointSize: 10
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Workspaces Settings Page
            ScrollView {
                clip: true
                
                ColumnLayout {
                    width: parent.width
                    anchors.margins: 30
                    spacing: 20
                    
                    Text {
                        text: "\udb80\udc3b Workspace Settings"
                        font.family: "Symbols Nerd Font"
                        font.pointSize: 20
                        font.bold: true
                        color: "#cdd6f4"
                        Layout.bottomMargin: 10
                    }
                    
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Workspace Management"
                        
                        background: Rectangle {
                            color: "#313244"
                            radius: 8
                            border.color: "#45475a"
                            border.width: 1
                        }
                        
                        label: Text {
                            text: parent.title
                            color: "#89b4fa"
                            font.bold: true
                            font.pointSize: 12
                        }
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 15
                            
                            Text {
                                text: "Workspace Management"
                                color: "#cdd6f4"
                                font.pointSize: 11
                            }
                            
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                
                                Button {
                                    text: "\uf067 New Workspace"
                                    onClicked: Hyprland.dispatch("workspace", "empty")
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#a6e3a1" : (parent.hovered ? "#94e2d5" : "#45475a")
                                        radius: 6
                                    }
                                    
                                    contentItem: Text {
                                        text: parent.text
                                        color: "#1e1e2e"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pointSize: 10
                                    }
                                }
                                
                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                }
            }
            
            // Appearance Settings Page
            ScrollView {
                clip: true
                
                ColumnLayout {
                    width: parent.width
                    anchors.margins: 30
                    spacing: 20
                    
                    Text {
                        text: "\uf53f Appearance Settings"
                        font.family: "Symbols Nerd Font"
                        font.pointSize: 20
                        font.bold: true
                        color: "#cdd6f4"
                        Layout.bottomMargin: 10
                    }
                    
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Theme Configuration"
                        
                        background: Rectangle {
                            color: "#313244"
                            radius: 8
                            border.color: "#45475a"
                            border.width: 1
                        }
                        
                        label: Text {
                            text: parent.title
                            color: "#89b4fa"
                            font.bold: true
                            font.pointSize: 12
                        }
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 15
                            
                            Text {
                                text: "Current Theme: Catppuccin Mocha"
                                color: "#cdd6f4"
                                font.pointSize: 11
                            }
                            
                            Text {
                                text: "Color Palette:"
                                color: "#89b4fa"
                                font.pointSize: 11
                                font.bold: true
                            }
                            
                            Flow {
                                Layout.fillWidth: true
                                spacing: 8
                                
                                Repeater {
                                    model: [
                                        {name: "Background", color: "#1e1e2e"},
                                        {name: "Surface", color: "#313244"},
                                        {name: "Blue", color: "#89b4fa"},
                                        {name: "Green", color: "#a6e3a1"},
                                        {name: "Red", color: "#f38ba8"},
                                        {name: "Text", color: "#cdd6f4"}
                                    ]
                                    
                                    Rectangle {
                                        width: 80
                                        height: 60
                                        color: modelData.color
                                        radius: 6
                                        border.color: "#45475a"
                                        border.width: 1
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.name
                                            color: modelData.name === "Background" || modelData.name === "Surface" ? "#cdd6f4" : "#1e1e2e"
                                            font.pointSize: 8
                                            font.bold: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // System Settings Page
            ScrollView {
                clip: true
                
                ColumnLayout {
                    width: parent.width
                    anchors.margins: 30
                    spacing: 20
                    
                    Text {
                        text: "\uf085 System Settings"
                        font.family: "Symbols Nerd Font"
                        font.pointSize: 20
                        font.bold: true
                        color: "#cdd6f4"
                        Layout.bottomMargin: 10
                    }
                    
                    GroupBox {
                        Layout.fillWidth: true
                        title: "Battery Information"
                        
                        background: Rectangle {
                            color: "#313244"
                            radius: 8
                            border.color: "#45475a"
                            border.width: 1
                        }
                        
                        label: Text {
                            text: parent.title
                            color: "#89b4fa"
                            font.bold: true
                            font.pointSize: 12
                        }
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10
                            
                            Text {
                                text: "Battery Level: " + Math.round(Battery.percentage) + "%"
                                color: "#cdd6f4"
                                font.pointSize: 11
                            }
                            
                            Text {
                                text: "Status: " + (Battery.charging ? "Charging" : "Discharging")
                                color: Battery.charging ? "#a6e3a1" : "#f9e2af"
                                font.pointSize: 11
                            }
                            
                            Text {
                                text: "Available: " + (Battery.exists ? "Yes" : "No")
                                color: Battery.exists ? "#a6e3a1" : "#f38ba8"
                                font.pointSize: 11
                            }
                        }
                    }
                    
                    GroupBox {
                        Layout.fillWidth: true
                        title: "QuickShell Actions"
                        
                        background: Rectangle {
                            color: "#313244"
                            radius: 8
                            border.color: "#45475a"
                            border.width: 1
                        }
                        
                        label: Text {
                            text: parent.title
                            color: "#89b4fa"
                            font.bold: true
                            font.pointSize: 12
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            spacing: 10
                            
                            Button {
                                text: "\uf021 Reload Config"
                                font.family: "Symbols Nerd Font"
                                onClicked: console.log("Config reload requested")
                                
                                background: Rectangle {
                                    color: parent.pressed ? "#f9e2af" : (parent.hovered ? "#fab387" : "#45475a")
                                    radius: 6
                                }
                                
                                contentItem: Text {
                                    text: parent.text
                                    font.family: "Symbols Nerd Font"
                                    color: "#1e1e2e"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pointSize: 10
                                }
                            }
                            
                            Button {
                                text: "\uf00d Quit QuickShell"
                                font.family: "Symbols Nerd Font"
                                onClicked: Qt.quit()
                                
                                background: Rectangle {
                                    color: parent.pressed ? "#f38ba8" : (parent.hovered ? "#eba0ac" : "#45475a")
                                    radius: 6
                                }
                                
                                contentItem: Text {
                                    text: parent.text
                                    font.family: "Symbols Nerd Font"
                                    color: "#cdd6f4"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pointSize: 10
                                }
                            }
                        }
                    }
                }
            }
            
            // About Page
            ScrollView {
                clip: true
                
                ColumnLayout {
                    width: parent.width
                    anchors.margins: 30
                    spacing: 20
                    
                    Text {
                        text: "\uf05a About"
                        font.family: "Symbols Nerd Font"
                        font.pointSize: 20
                        font.bold: true
                        color: "#cdd6f4"
                        Layout.bottomMargin: 10
                    }
                    
                    GroupBox {
                        Layout.fillWidth: true
                        title: "QuickShell Information"
                        
                        background: Rectangle {
                            color: "#313244"
                            radius: 8
                            border.color: "#45475a"
                            border.width: 1
                        }
                        
                        label: Text {
                            text: parent.title
                            color: "#89b4fa"
                            font.bold: true
                            font.pointSize: 12
                        }
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 15
                            
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "\uf135 QuickShell Configuration Manager"
                            color: "#cdd6f4"
                            font.pointSize: 13
                            font.bold: true
                        }                            Text {
                                text: "A customizable Wayland shell built with Qt/QML"
                                color: "#a6adc8"
                                font.pointSize: 11
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#45475a"
                            }
                            
                            Text {
                                text: "Features:"
                                color: "#89b4fa"
                                font.pointSize: 11
                                font.bold: true
                            }
                            
                            Column {
                                spacing: 5
                                
                                Repeater {
                                    model: [
                                        " Centered workspace display",
                                        " Circular volume and battery widgets",
                                        " Real-time system monitoring",
                                        " Catppuccin theme integration",
                                        " Hyprland workspace management",
                                        " PipeWire audio control"
                                    ]
                                    
                                    Text {
                                        text: modelData
                                        font.family: "Symbols Nerd Font"
                                        color: "#a6e3a1"
                                        font.pointSize: 10
                                    }
                                }
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: "#45475a"
                            }
                            
                            Text {
                                text: "Configuration Path: /home/oleh/rice/quickshell-config"
                                color: "#a6adc8"
                                font.pointSize: 9
                                font.family: "monospace"
                            }
                        }
                    }
                }
            }
        }
    }
}
