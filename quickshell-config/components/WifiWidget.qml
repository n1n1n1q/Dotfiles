import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: wifiWidget
    spacing: Theme.spacing.small
    
    Text {
        text: NetworkService.wifiIcon
        font.family: Theme.font.icon
        font.pointSize: Theme.bar.iconSize
        color: NetworkService.connected ? Theme.colors.success : Theme.colors.error
        
        Behavior on color {
            ColorAnimation { duration: Theme.animation.fast }
        }
    }
    
    Text {
        text: NetworkService.ssid
        font.pointSize: Theme.bar.fontSizeSmall
        color: Theme.colors.textPrimary
        visible: NetworkService.connected && NetworkService.ssid !== ""
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Toggle network settings or show network menu
            print("WiFi clicked")
        }
    }
}
