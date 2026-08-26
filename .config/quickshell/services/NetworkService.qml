pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: networkService
    
    property bool connected: false
    property string ssid: ""
    property int strength: 0
    property string wifiIcon: "󰖩"
    
    // This is a simplified network service
    // You would typically use NetworkManager or similar
    
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: updateNetworkStatus()
    }
    
    Component.onCompleted: updateNetworkStatus()
    
    function updateNetworkStatus() {
        // This would typically query NetworkManager
        // For now, using placeholder logic
        connected = true
        ssid = "Home WiFi"
        strength = 75
        
        if (strength > 75) wifiIcon = "󰖩"
        else if (strength > 50) wifiIcon = "󰖩"
        else if (strength > 25) wifiIcon = "󰖩"
        else wifiIcon = "󰖩"
    }
}
