import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.modules.settings

// One Bluetooth device — a segmented SettingsGroup sub-block. Tapping the row
// runs the primary action (connect / disconnect for paired devices, pair for
// new ones); the chevron opens Forget / explicit connect actions.
Rectangle {
    id: root

    required property var device
    property string blockPosition: "single"

    readonly property bool isConnected: device.connected
    readonly property bool isPaired: device.paired || device.bonded
    readonly property bool busy: Bluetooth.deviceBusy(device)

    property bool expanded: false

    readonly property int _r: Theme.workspace.indicatorRadius
    readonly property bool _rt: blockPosition === "top" || blockPosition === "single"
    readonly property bool _rb: blockPosition === "bottom" || blockPosition === "single"

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + Theme.spacing.small * 2
    color: Theme.colors.surface
    topLeftRadius: _rt ? _r : 0
    topRightRadius: _rt ? _r : 0
    bottomLeftRadius: _rb ? _r : 0
    bottomRightRadius: _rb ? _r : 0

    function primary() {
        if (busy)
            return;
        if (isPaired)
            device.connected = !device.connected;
        else
            device.pair();
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
                    color: root.isConnected ? Theme.colors.accent : Theme.colors.surfaceVariant

                    Text {
                        anchors.centerIn: parent
                        text: Bluetooth.deviceGlyph(root.device.icon)
                        font.family: Theme.font.icon
                        font.pointSize: Theme.font.large
                        color: root.isConnected ? Theme.colors.bg : Theme.colors.textPrimary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: -1

                    Text {
                        Layout.fillWidth: true
                        text: root.device.name || root.device.deviceName || root.device.address
                        elide: Text.ElideRight
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.medium
                        font.weight: Theme.font.mediumWeight
                        color: Theme.colors.textPrimary
                    }

                    Text {
                        Layout.fillWidth: true
                        text: Bluetooth.deviceState(root.device)
                        elide: Text.ElideRight
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.small
                        color: root.isConnected ? Theme.colors.success : Theme.colors.textTertiary
                    }
                }

                BusyIndicator {
                    visible: root.busy
                    running: root.busy
                    implicitWidth: 22
                    implicitHeight: 22
                }

                // chevron — opens the actions row
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.isPaired && !root.busy
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: height / 2
                    color: chevron.containsMouse ? Theme.colors.surfaceVariant : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅀"
                        rotation: root.expanded ? 180 : 0
                        font.family: Theme.font.icon
                        font.pointSize: Theme.font.medium
                        color: Theme.colors.textSecondary
                        Behavior on rotation { NumberAnimation { duration: Theme.animation.fast } }
                    }

                    MouseArea {
                        id: chevron
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = !root.expanded
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: root.isPaired ? 36 : 0
                cursorShape: Qt.PointingHandCursor
                onClicked: root.primary()
            }
        }

        // --- actions --------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Theme.spacing.small
            visible: root.expanded
            spacing: Theme.spacing.small

            Item { Layout.fillWidth: true }

            PillButton {
                text: "Forget"
                danger: true
                onClicked: {
                    root.device.forget();
                    root.expanded = false;
                }
            }

            PillButton {
                text: root.isConnected ? "Disconnect" : "Connect"
                accent: !root.isConnected
                onClicked: {
                    root.device.connected = !root.device.connected;
                    root.expanded = false;
                }
            }
        }
    }
}
