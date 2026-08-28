import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.modules.settings

SettingsPage {
    id: page
    heading: "Bluetooth"
    icon: "󰂯"
    blurb: "Adapter power, visibility and paired devices, via BlueZ."

    // Scan only while the user asked for it AND this page is on screen.
    property bool wantScan: false
    readonly property bool pageActive: SettingsController.section === "bluetooth"

    function syncScan() {
        Bluetooth.scan(wantScan && pageActive && Bluetooth.enabled);
    }
    onWantScanChanged: syncScan()
    onPageActiveChanged: {
        if (!pageActive)
            wantScan = false;
        syncScan();
    }
    Component.onDestruction: Bluetooth.scan(false)

    // --- adapter ---------------------------------------------------------------
    SettingsGroup {
        SettingsRow {
            icon: Bluetooth.icon
            title: "Bluetooth"
            subtitle: !Bluetooth.available ? "No adapter found"
                : !Bluetooth.enabled ? "Off"
                : Bluetooth.connectedDeviceCount > 0 ? (Bluetooth.connectedDeviceCount + " connected")
                : "On"
            SettingsToggle {
                checked: Bluetooth.enabled
                busy: !Bluetooth.available
                onToggled: Bluetooth.toggleBluetooth()
            }
        }

        SettingsRow {
            visible: Bluetooth.enabled
            icon: "󰈈"
            title: "Discoverable"
            subtitle: "Let nearby devices find this machine"
            SettingsToggle {
                checked: Bluetooth.discoverable
                onToggled: checked => Bluetooth.setDiscoverable(checked)
            }
        }

        SettingsRow {
            visible: Bluetooth.enabled
            icon: "󰌷"
            title: "Pairable"
            subtitle: "Accept new pairing requests"
            SettingsToggle {
                checked: Bluetooth.pairable
                onToggled: checked => Bluetooth.setPairable(checked)
            }
        }
    }

    // --- paired devices ------------------------------------------------------
    SettingsGroup {
        visible: Bluetooth.enabled

        Repeater {
            model: Bluetooth.pairedDevices
            delegate: BluetoothDeviceRow {
                required property var modelData
                device: modelData
            }
        }

        SettingsRow {
            visible: Bluetooth.pairedDevices.length === 0
            icon: "󰂲"
            title: "No paired devices"
            subtitle: "Scan below to add one"
        }
    }

    // --- discovery -----------------------------------------------------------
    SettingsGroup {
        visible: Bluetooth.enabled

        SettingsRow {
            icon: "󰐧"
            title: "Scan for devices"
            subtitle: page.wantScan
                ? (Bluetooth.discovering ? "Scanning…" : "Starting…")
                : "Put your device in pairing mode first"

            BusyIndicator {
                visible: page.wantScan && Bluetooth.discovering
                running: visible
                implicitWidth: 22
                implicitHeight: 22
            }
            SettingsToggle {
                checked: page.wantScan
                onToggled: checked => page.wantScan = checked
            }
        }

        Repeater {
            model: page.wantScan ? Bluetooth.discoveredDevices : []
            delegate: BluetoothDeviceRow {
                required property var modelData
                device: modelData
            }
        }
    }

    // --- off / missing -----------------------------------------------------
    SettingsPlaceholder {
        visible: !Bluetooth.available || !Bluetooth.enabled
        icon: "󰂲"
        label: !Bluetooth.available ? "No Bluetooth adapter" : "Bluetooth is off"
        hint: !Bluetooth.available
            ? "Nothing to configure — no BlueZ adapter is present."
            : "Turn it on to see paired devices and scan for new ones."
    }
}
