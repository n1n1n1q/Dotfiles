import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.modules.settings

SettingsPage {
    id: page
    heading: "Wi‑Fi"
    icon: "󰤨"
    blurb: "Wireless networking, handled by NetworkManager."

    // --- radio + scan ------------------------------------------------------
    SettingsGroup {
        SettingsRow {
            icon: WiFi.enabled ? "󰤨" : "󰤪"
            title: "Wi‑Fi"
            subtitle: !WiFi.enabled ? "Off"
                : WiFi.connected ? ("Connected to " + WiFi.ssid)
                : "On"
            SettingsToggle {
                checked: WiFi.enabled
                onToggled: WiFi.toggleWifi()
            }
        }

        SettingsRow {
            visible: WiFi.enabled
            icon: "󰑓"
            title: "Scan for networks"
            subtitle: WiFi.scanning ? "Scanning…" : (WiFi.networks.length + " found")

            BusyIndicator {
                visible: WiFi.scanning
                running: WiFi.scanning
                implicitWidth: 22
                implicitHeight: 22
            }
            PillButton {
                visible: !WiFi.scanning
                text: "Rescan"
                onClicked: WiFi.scan()
            }
        }
    }

    // --- network list -------------------------------------------------------
    SettingsGroup {
        visible: WiFi.enabled

        Repeater {
            model: WiFi.networks

            delegate: WifiNetworkRow {
                required property var modelData
                network: modelData
            }
        }

        SettingsRow {
            visible: WiFi.networks.length === 0
            icon: "󰤯"
            title: WiFi.scanning ? "Looking for networks…" : "No networks found"
            subtitle: WiFi.scanning ? "" : "Move closer to an access point or rescan"
        }
    }

    // --- wifi off notice ---------------------------------------------------
    SettingsPlaceholder {
        visible: !WiFi.enabled
        icon: "󰤪"
        label: "Wi‑Fi is off"
        hint: "Turn it on to scan for and join networks."
    }
}
