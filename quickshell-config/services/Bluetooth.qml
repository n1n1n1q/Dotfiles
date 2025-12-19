pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

Singleton {
    id: root

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)
    readonly property int connectedDeviceCount: Bluetooth.defaultAdapter?.devices.values.filter(d => d.connected).length ?? 0
    readonly property var firstConnectedDevice: Bluetooth.defaultAdapter?.devices.values.find(d => d.connected) ?? null
    readonly property string icon: getBluetoothIcon()

    function getBluetoothIcon() {
        if (!available) return "󰂲"
        if (!enabled) return "󰂲"
        if (connected) return "󰂱"
        return "󰂯"
    }

    function toggleBluetooth() {
        console.log("Toggling Bluetooth. Current state:", enabled)
        console.log("Available:", available)
        console.log("Adapter:", Bluetooth.defaultAdapter)
        
        if (!available) {
            console.warn("No Bluetooth adapter available")
            return
        }
        
        const adapter = Bluetooth.defaultAdapter
        if (adapter) {
            const newState = !enabled
            adapter.enabled = newState
            console.log("Bluetooth toggle requested, new state:", newState)
        } else {
            console.warn("Bluetooth defaultAdapter is null")
        }
    }

    function enableBluetooth(enable) {
        if (!available) return
        
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.enabled = enable
        }
    }

    function setDiscoverable(discoverable) {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.discoverable = discoverable
        }
    }

    function setPairable(pairable) {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.pairable = pairable
        }
    }

    function connectDevice(device) {
        if (device) {
            device.connected = true
        }
    }

    function disconnectDevice(device) {
        if (device) {
            device.connected = false
        }
    }

    function getDeviceIcon(systemIconName) {
        // Map Bluetooth device types to icons
        if (!systemIconName) return "󰂯"
        
        const iconName = systemIconName.toLowerCase()
        
        if (iconName.includes("audio") || iconName.includes("headset") || 
            iconName.includes("headphone")) return "󰋋"
        if (iconName.includes("phone")) return "󰄜"
        if (iconName.includes("computer")) return "󰇄"
        if (iconName.includes("mouse")) return "󰍽"
        if (iconName.includes("keyboard")) return "󰌌"
        if (iconName.includes("gamepad") || iconName.includes("joystick")) return "󰖺"
        
        return "󰂯"
    }

    Component.onCompleted: {
        console.log("Bluetooth service initialized")
        console.log("Bluetooth available:", available)
        console.log("Bluetooth enabled:", enabled)
        console.log("Connected devices:", connectedDeviceCount)
        console.log("Adapters:", Bluetooth.adapters.values.length)
        console.log("Default adapter:", Bluetooth.defaultAdapter)
    }
}
