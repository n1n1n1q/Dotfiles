pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool enabled: true
    property bool connected: false
    property string ssid: ""
    property int strength: 0
    property string icon: getWifiIcon()
    readonly property bool scanning: rescanProc.running

    function getWifiIcon() {
        if (!enabled) return "󰖪"  // wifi_off
        if (!connected) return "�"  // wifi (enabled but not connected)
        // Return icon based on signal strength when connected
        if (strength > 75) return "󰖩"  // wifi_4_bar
        if (strength > 50) return "󰖨"  // wifi_3_bar
        if (strength > 25) return "󰖧"  // wifi_2_bar
        return "󰖩"  // wifi_1_bar (fallback)
    }

    function toggleWifi() {
        const cmd = enabled ? "off" : "on"
        toggleProc.exec(["nmcli", "radio", "wifi", cmd])
    }

    function rescan() {
        rescanProc.running = true
    }

    function connectToNetwork(ssid, password) {
        if (password) {
            connectProc.exec(["nmcli", "dev", "wifi", "connect", ssid, "password", password])
        } else {
            connectProc.exec(["nmcli", "dev", "wifi", "connect", ssid])
        }
    }

    function disconnect() {
        if (connected && ssid) {
            disconnectProc.exec(["nmcli", "connection", "down", ssid])
        }
    }

    // Monitor WiFi status
    Process {
        running: true
        command: ["nmcli", "m"]
        stdout: SplitParser {
            onRead: getStatusProc.running = true
        }
    }

    // Get WiFi enabled status
    Process {
        id: getStatusProc
        running: true
        command: ["nmcli", "radio", "wifi"]
        environment: ({
            LANG: "C.UTF-8",
            LC_ALL: "C.UTF-8"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root.enabled = text.trim() === "enabled"
                if (root.enabled) {
                    getConnectionProc.running = true
                }
                root.icon = root.getWifiIcon()
            }
        }
    }

    // Get current connection info
    Process {
        id: getConnectionProc
        running: true
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi"]
        environment: ({
            LANG: "C.UTF-8",
            LC_ALL: "C.UTF-8"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const activeLine = lines.find(line => line.startsWith("yes:"))
                
                if (activeLine) {
                    const parts = activeLine.split(":")
                    root.connected = true
                    root.ssid = parts[1] || ""
                    root.strength = parseInt(parts[2]) || 0
                } else {
                    root.connected = false
                    root.ssid = ""
                    root.strength = 0
                }
                
                root.icon = root.getWifiIcon()
            }
        }
    }

    // Toggle WiFi
    Process {
        id: toggleProc
        onExited: {
            getStatusProc.running = true
        }
    }

    // Rescan WiFi
    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: {
            getConnectionProc.running = true
        }
    }

    // Connect to network
    Process {
        id: connectProc
        stdout: SplitParser {
            onRead: getConnectionProc.running = true
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text) console.warn("WiFi connection error:", text)
            }
        }
    }

    // Disconnect from network
    Process {
        id: disconnectProc
        onExited: {
            getConnectionProc.running = true
        }
    }

    // Timer for periodic updates
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            if (root.enabled) {
                getConnectionProc.running = true
            }
        }
    }

    Component.onCompleted: {
        console.log("WiFi service initialized")
    }
}
