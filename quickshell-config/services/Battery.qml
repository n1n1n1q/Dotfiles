pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root
    
    readonly property real percentage: UPower.displayDevice?.percentage ?? 0
    readonly property bool charging: UPower.displayDevice?.state === UPowerDeviceState.Charging
    readonly property bool isLow: percentage < 0.2 && !charging
    readonly property bool isLaptopBattery: UPower.displayDevice?.isLaptopBattery ?? false
    readonly property int timeToEmpty: UPower.displayDevice?.timeToEmpty ?? 0
    readonly property int timeToFull: UPower.displayDevice?.timeToFull ?? 0
    readonly property real energyRate: UPower.displayDevice?.changeRate ?? 0
    readonly property var state: UPower.displayDevice?.state ?? UPowerDeviceState.Unknown
    
    readonly property string icon: {
        if (charging) return "\uf0e7"
        if (isLow) return "\uf244"
        return "\uf240"
    }
    
    readonly property color color: {
        if (charging) return "#f9e2af"
        if (isLow) return "#f38ba8"
        if (percentage > 0.75) return "#a6e3a1"
        if (percentage > 0.5) return "#fab387"
        return "#f9e2af"
    }
    
    function formatTime(seconds) {
        if (seconds <= 0) return "Calculating..."
        
        var h = Math.floor(seconds / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        
        if (h > 0)
            return h + "h " + m + "m"
        else
            return m + "m"
    }
    
    readonly property string timeRemaining: {
        if (!isLaptopBattery) return ""
        if (state === UPowerDeviceState.FullyCharged) return "Fully charged"
        
        if (charging) {
            if (timeToFull > 0)
                return "Time to full: " + formatTime(timeToFull)
            return "Charging"
        } else {
            if (timeToEmpty > 0)
                return "Time to empty: " + formatTime(timeToEmpty)
            return "Discharging"
        }
    }
}
