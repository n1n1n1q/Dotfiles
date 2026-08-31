import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.modules.settings

// One access point in the Wi-Fi list — a segmented SettingsGroup sub-block that
// expands in place to ask for a password (or username + password for
// enterprise networks), or to offer disconnect / forget on the active one.
Rectangle {
    id: root

    required property var network
    // Set by the enclosing SettingsGroup; a row without one paints its own
    // surface so it still reads as a card on its own.
    property bool inGroup: false

    readonly property string ssid: network.ssid
    readonly property bool isActive: network.active
    readonly property bool busy: WiFi.connecting && WiFi.busySsid === ssid
    readonly property bool hasError: WiFi.errorSsid === ssid
    readonly property bool needsPrompt: network.secure && !network.known

    property bool expanded: false
    onHasErrorChanged: if (hasError) expanded = true


    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + Theme.spacing.small * 2
    radius: Theme.rounding.large
    color: inGroup ? "transparent" : Theme.colors.surface

    function submit() {
        if (network.enterprise)
            WiFi.connectEnterprise(ssid, userField.text, pwField.text);
        else
            WiFi.connectWithPassword(ssid, pwField.text);
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Theme.spacing.small
        anchors.leftMargin: Theme.spacing.normal
        anchors.rightMargin: Theme.spacing.normal
        spacing: Theme.spacing.small

        // --- main line ---------------------------------------------------
        Item {
            Layout.fillWidth: true
            implicitHeight: 42

            RowLayout {
                anchors.fill: parent
                spacing: Theme.spacing.normal

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: Theme.rounding.small
                    color: root.isActive ? Theme.colors.accent : Theme.colors.surfaceVariant

                    Text {
                        anchors.centerIn: parent
                        text: WiFi.signalIcon(root.network.signal)
                        font.family: Theme.font.icon
                        font.pointSize: Theme.font.large
                        color: root.isActive ? Theme.colors.bg : Theme.colors.textPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: -1

                    Text {
                        Layout.fillWidth: true
                        text: root.ssid
                        elide: Text.ElideRight
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.medium
                        font.weight: Theme.font.mediumWeight
                        color: Theme.colors.textPrimary
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.busy ? "Connecting…"
                            : root.isActive ? "Connected"
                            : (root.hasError ? WiFi.errorText
                            : root.network.known ? "Saved"
                            : root.network.enterprise ? "Enterprise · sign-in required"
                            : root.network.secure ? "Password required"
                            : "Open")
                        elide: Text.ElideRight
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.small
                        color: root.hasError ? Theme.colors.error : Theme.colors.textTertiary
                    }
                }

                BusyIndicator {
                    visible: root.busy
                    running: root.busy
                    implicitWidth: 22
                    implicitHeight: 22
                }

                Text {
                    visible: !root.busy && (root.isActive || root.network.secure)
                    text: root.isActive ? "󰄬" : root.network.secure ? "󰌾" : ""
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.medium
                    color: root.isActive ? Theme.colors.success : Theme.colors.textTertiary
                }

                Text {
                    text: root.network.signal + "%"
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.small
                    font.features: ({ "tnum": 1 })
                    color: Theme.colors.textTertiary
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.isActive || root.needsPrompt)
                        root.expanded = !root.expanded;
                    else
                        WiFi.connect(root.ssid);
                    WiFi.clearError();
                }
            }
        }

        // --- password / username prompt --------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Theme.spacing.small
            visible: root.expanded && !root.isActive
            spacing: Theme.spacing.small

            WifiField {
                id: userField
                visible: root.network.enterprise
                placeholder: "Username"
                icon: "󰀄"
            }

            WifiField {
                id: pwField
                placeholder: "Password"
                icon: "󰌾"
                secret: true
                onAccepted: root.submit()
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.small

                Item { Layout.fillWidth: true }

                PillButton {
                    text: "Cancel"
                    onClicked: {
                        root.expanded = false;
                        pwField.clear();
                        WiFi.clearError();
                    }
                }

                PillButton {
                    text: "Connect"
                    accent: true
                    enabledButton: pwField.text.length > 0
                        && (!root.network.enterprise || userField.text.length > 0)
                    onClicked: root.submit()
                }
            }
        }

        // --- active-network actions -----------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Theme.spacing.small
            visible: root.expanded && root.isActive
            spacing: Theme.spacing.small

            Item { Layout.fillWidth: true }

            PillButton {
                text: "Forget"
                danger: true
                visible: root.network.known
                onClicked: {
                    WiFi.forget(root.ssid);
                    root.expanded = false;
                }
            }

            PillButton {
                text: "Disconnect"
                onClicked: {
                    WiFi.disconnectFrom(root.ssid);
                    root.expanded = false;
                }
            }
        }
    }
}
