import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

Button {
    id: root
    
    required property string name
    required property string iconName
    required property bool active
    property bool connected: false  // Optional: shows connection status
    signal buttonClicked()
    
    Layout.preferredWidth: 48
    Layout.preferredHeight: 48
    
    onClicked: root.buttonClicked()
    
    background: Rectangle {
        color: root.active ? Theme.colors.accent : 
               (root.pressed ? Theme.colors.borderSubtle : 
               (root.hovered ? Theme.colors.surfaceVariant : Theme.colors.surface))
        radius: Theme.rounding.full
        
        Behavior on color {
            ColorAnimation { 
                duration: Theme.animation.fast
                easing.type: Theme.animation.easeOut
            }
        }
        
        // Connection indicator dot (top-right corner)
        Rectangle {
            visible: root.active && root.connected
            width: 8
            height: 8
            radius: 4
            color: Theme.colors.success
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacing.small
            
            // Subtle pulse animation
            SequentialAnimation on scale {
                running: root.active && root.connected
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.2; duration: 1000; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 1.2; to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
            }
        }
    }
    
    contentItem: Item {
        anchors.fill: parent
        
        Text {
            anchors.centerIn: parent
            text: getIconText()
            font.family: Theme.font.icon
            font.pointSize: 16
            color: root.active ? Theme.colors.bg : Theme.colors.textPrimary
            
            function getIconText() {
                const iconMap = {
                    "wifi": getWifiIcon(),
                    "bluetooth": getBluetoothIcon(),
                    "screenshot": "\udb80\udd00",
                    "lock": "\ue672",
                    "record": "\udb81\udd67",
                    "settings": "\ueb52"
                }
                return iconMap[root.iconName] || root.iconName
            }
            
            function getWifiIcon() {
                if (!root.active) return "󰖪"  // wifi_off
                if (root.connected) return "󰖩"  // wifi_on (strong)
                return "󰖩"  // wifi_on (not connected)
            }
            
            function getBluetoothIcon() {
                if (!root.active) return "󰂲"  // bluetooth_disabled
                if (root.connected) return "󰂱"  // bluetooth_connected
                return "󰂯"  // bluetooth (enabled, not connected)
            }
        }
    }
}
