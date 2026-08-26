pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real brightness: 0.5
    
    readonly property Process initProc: Process {
        running: true
        command: ["sh", "-c", "brightnessctl g"]
        
        stdout: SplitParser {
            onRead: data => {
                const current = parseInt(data.trim())
                if (!isNaN(current) && current > 0) {
                    getMaxProc.running = true
                }
            }
        }
    }
    
    readonly property Process getMaxProc: Process {
        command: ["sh", "-c", "brightnessctl m"]
        
        stdout: SplitParser {
            onRead: data => {
                const max = parseInt(data.trim())
                const current = parseInt(initProc.stdout)
                if (!isNaN(max) && max > 0 && !isNaN(current)) {
                    root.brightness = current / max
                }
            }
        }
    }
    
    function setBrightness(value) {
        // Clamp value between 0.05 and 1.0 (don't go completely dark)
        const clampedValue = Math.max(0.05, Math.min(1.0, value))
        
        if (Math.abs(clampedValue - root.brightness) < 0.01) {
            return // Skip tiny changes
        }
        
        root.brightness = clampedValue
        const percent = Math.round(clampedValue * 100)
        
        Quickshell.execDetached(["brightnessctl", "s", `${percent}%`])
        
        console.log("Brightness set to:", percent + "%")
    }
    
    function incrementBrightness(amount = 0.1) {
        setBrightness(brightness + amount)
    }
    
    function decrementBrightness(amount = 0.1) {
        setBrightness(brightness - amount)
    }
    
    function getBrightnessIcon() {
        if (brightness > 0.66) return "󰃠" // High brightness
        if (brightness > 0.33) return "󰃟" // Medium brightness
        return "󰃞" // Low brightness
    }
}
