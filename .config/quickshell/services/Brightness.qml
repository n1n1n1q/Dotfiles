pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Backlight brightness as a 0..1 value.
//
// niri changes brightness out-of-process (the XF86MonBrightness* keys spawn
// `brightnessctl` directly - see ~/.config/niri/config.kdl), so there's no
// in-shell signal for a hardware key press. Instead of polling, watch udev
// for `backlight` subsystem `change` events and re-read on each one; that's
// event-driven and costs nothing while idle. The dashboard slider path
// (setBrightness) also lands here via the same udev echo.
//
// `brightness` is quantised to whole percent so an external change and an
// internal one converge on the same number and don't ping-pong the change
// signal (which drives the OSD).
Singleton {
    id: root

    property real brightness: 0.5

    function refresh() {
        readProc.running = true
    }

    Process {
        id: readProc
        running: true
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: line => {
                // name,class,current,NN%,max
                const parts = line.trim().split(",")
                if (parts.length < 4)
                    return
                const pct = parseInt(parts[3])
                if (!isNaN(pct))
                    root.brightness = Math.max(0, Math.min(1, pct / 100))
            }
        }
    }

    Process {
        running: true
        command: ["stdbuf", "-oL", "udevadm", "monitor", "--udev", "--subsystem-match=backlight"]
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("change") !== -1)
                    refreshDebounce.restart()
            }
        }
    }

    Timer {
        id: refreshDebounce
        interval: 50
        onTriggered: root.refresh()
    }

    function setBrightness(value) {
        // Clamp between 5% and 100% (don't go fully dark).
        const clamped = Math.max(0.05, Math.min(1.0, value))
        const percent = Math.round(clamped * 100)

        if (percent === Math.round(root.brightness * 100))
            return

        root.brightness = percent / 100
        Quickshell.execDetached(["brightnessctl", "s", `${percent}%`])
    }

    function incrementBrightness(amount = 0.1) {
        setBrightness(brightness + amount)
    }

    function decrementBrightness(amount = 0.1) {
        setBrightness(brightness - amount)
    }

    // Every glyph getBrightnessIcon() can return — a cell that draws one
    // sizes itself from the set so it holds still as the level moves.
    readonly property var iconStates: ["󰃠", "󰃟", "󰃞"]

    function getBrightnessIcon() {
        if (brightness > 0.66) return "󰃠" // High brightness
        if (brightness > 0.33) return "󰃟" // Medium brightness
        return "󰃞" // Low brightness
    }
}
