pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

// Thin wrapper over Quickshell.Bluetooth (BlueZ). Exposes the default adapter,
// sorted device lists and a scan toggle; connect / pair / forget happen on the
// BluetoothDevice objects directly.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: adapter?.enabled ?? false
    readonly property bool discovering: adapter?.discovering ?? false
    readonly property bool discoverable: adapter?.discoverable ?? false
    readonly property bool pairable: adapter?.pairable ?? false

    readonly property var devices: Bluetooth.devices.values
    readonly property bool connected: devices.some(d => d.connected)
    readonly property int connectedDeviceCount: devices.filter(d => d.connected).length
    readonly property var firstConnectedDevice: devices.find(d => d.connected) ?? null

    function _sort(a, b) {
        // real names before bare MAC addresses, then alphabetical
        const mac = /^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$/;
        const am = mac.test(a.name || a.address);
        const bm = mac.test(b.name || b.address);
        if (am !== bm)
            return am ? 1 : -1;
        return (a.name || a.address).localeCompare(b.name || b.address);
    }

    readonly property var pairedDevices: devices
        .filter(d => d.paired || d.bonded)
        .sort((a, b) => (b.connected - a.connected) || _sort(a, b))
    readonly property var discoveredDevices: devices
        .filter(d => !(d.paired || d.bonded))
        .sort((a, b) => (b.pairing - a.pairing) || _sort(a, b))

    readonly property string icon: {
        if (!available || !enabled) return "󰂲"     // bluetooth-off
        if (connected) return "󰂱"                   // bluetooth-connect
        return "󰂯"                                  // bluetooth
    }

    // --- actions ---------------------------------------------------------------
    function toggleBluetooth() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }
    function setEnabled(on) {
        if (adapter)
            adapter.enabled = on;
    }
    function setDiscoverable(on) {
        if (adapter)
            adapter.discoverable = on;
    }
    function setPairable(on) {
        if (adapter)
            adapter.pairable = on;
    }
    function scan(on) {
        if (adapter && adapter.enabled)
            adapter.discovering = on;
    }

    // freedesktop icon name -> nerd-font glyph
    function deviceGlyph(name) {
        const n = (name || "").toLowerCase();
        if (n.includes("headset") || n.includes("headphone") || n.includes("audio-headphones")) return "󰋋";
        if (n.includes("audio") || n.includes("speaker")) return "󰓃";
        if (n.includes("phone")) return "󰄜";
        if (n.includes("computer") || n.includes("laptop")) return "󰌢";
        if (n.includes("mouse")) return "󰦋";
        if (n.includes("keyboard")) return "󰌌";
        if (n.includes("gamepad") || n.includes("joystick") || n.includes("input-gaming")) return "󰊗";
        if (n.includes("watch")) return "󰖉";
        if (n.includes("printer")) return "󰐪";
        if (n.includes("camera")) return "󰄀";
        if (n.includes("display") || n.includes("tv") || n.includes("video")) return "󰍹";
        return "󰂯";
    }

    function deviceState(d) {
        if (!d) return "";
        if (d.pairing) return "Pairing…";
        if (d.state === BluetoothDeviceState.Connecting) return "Connecting…";
        if (d.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…";
        if (d.connected) {
            let s = "Connected";
            if (d.batteryAvailable) s += "  ·  " + Math.round(d.battery * 100) + "%";
            return s;
        }
        if (d.paired || d.bonded) return "Paired";
        return d.address;
    }
    function deviceBusy(d) {
        return d && (d.pairing
            || d.state === BluetoothDeviceState.Connecting
            || d.state === BluetoothDeviceState.Disconnecting);
    }
}
