pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.services.niri
import qs.modules.osd

// The OSD's state + trigger logic, split out from its view so one instance
// drives the per-screen OsdView cards hosted by the Drawers window. Was the
// top of Osd.qml (a Scope holding shared state above a per-screen Variants).
Item {
    id: root

    // "volume" | "brightness" | "language" | "wallpaper" | "scheme" | "preset" | "dnd"
    property string mode: "volume"
    property string presetName: ""
    readonly property alias shown: visState.shown

    // Suppress the OSD during startup while services publish their first values.
    property bool ready: false
    Timer {
        interval: 2000
        running: true
        onTriggered: root.ready = true
    }

    QtObject {
        id: visState
        property bool shown: false
    }

    Timer {
        id: hideTimer
        interval: Theme.popup.osdTimeout
        onTriggered: visState.shown = false
    }

    function trigger(m) {
        // Whoever holds the inhibit is already showing this level on screen
        // (the dashboard's sliders), so the pill would just duplicate it.
        if (OsdController.inhibited && (m === "volume" || m === "brightness")) {
            visState.shown = false
            hideTimer.stop()
            return
        }
        root.mode = m
        visState.shown = true
        hideTimer.restart()
    }

    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() { if (root.ready) root.trigger("volume") }
        function onMutedChanged() { if (root.ready) root.trigger("volume") }
    }

    Connections {
        target: Brightness
        function onBrightnessChanged() { if (root.ready) root.trigger("brightness") }
    }

    Connections {
        target: NiriService
        function onKeyboardLayoutIdxChanged() { if (root.ready) root.trigger("language") }
    }

    Connections {
        target: Notifications
        function onDoNotDisturbChanged() { if (root.ready) root.trigger("dnd") }
    }

    Connections {
        target: Wallpaper
        function onCycled() { root.trigger("wallpaper") }
    }

    Connections {
        target: Appearance
        function onSchemeCycled() { root.trigger("scheme") }
    }

    Connections {
        target: Presets
        function onPresetApplied(name) {
            root.presetName = name
            root.trigger("preset")
        }
    }

    // --- derived display values ----------------------------------------

    readonly property bool isLevel: mode === "volume" || mode === "brightness"

    readonly property bool iconInside:
        DashboardConfig.sliderStyleEntry(OsdConfig.sliderStyle).iconInside === true

    readonly property real value: {
        if (mode === "brightness")
            return Brightness.brightness
        if (mode === "volume")
            return Audio.muted ? 0 : Audio.volume
        return 0
    }

    readonly property bool hasThumb: mode === "wallpaper" && Wallpaper.current.length > 0

    readonly property var iconStates: Audio.volumeGlyphs
        .concat(Brightness.iconStates)
        .concat(["󰌌", "󰸉", "󰏘", "󰏗", "󰂛", "󰂚"])

    readonly property string icon: {
        if (mode === "brightness")
            return Brightness.getBrightnessIcon()
        if (mode === "language")
            return "󰌌"
        if (mode === "wallpaper")
            return "󰸉"
        if (mode === "scheme")
            return "󰏘"
        if (mode === "preset")
            return "󰏗"
        if (mode === "dnd")
            return Notifications.doNotDisturb ? "󰂛" : "󰂚"
        if (Audio.muted || Audio.volume <= 0.01)
            return "󰖁"
        if (Audio.volume <= 0.33)
            return "󰕿"
        if (Audio.volume <= 0.66)
            return "󰖀"
        return "󰕾"
    }

    readonly property string label: {
        if (mode === "brightness")
            return "Brightness"
        if (mode === "language")
            return "Keyboard layout"
        if (mode === "wallpaper")
            return "Wallpaper"
        if (mode === "scheme")
            return "Colour scheme"
        if (mode === "preset")
            return "Preset"
        if (mode === "dnd")
            return "Do Not Disturb"
        return Audio.muted ? "Muted" : "Volume"
    }

    readonly property string caption: {
        if (mode === "language")
            return NiriService.keyboardLayoutName
        if (mode === "scheme")
            return Appearance.schemeName
        if (mode === "preset")
            return root.presetName
        if (mode === "dnd")
            return Notifications.doNotDisturb ? "On — popups silenced" : "Off"
        if (mode === "wallpaper")
            return Wallpaper.current.length === 0
                ? "Folder is empty"
                : Wallpaper.current.split("/").pop().replace(/\.[^.]+$/, "")
        return ""
    }

    readonly property string counter: {
        if (isLevel)
            return Math.round(value * 100) + "%"
        if (mode === "wallpaper" && Wallpaper.currentIndex >= 0)
            return (Wallpaper.currentIndex + 1) + "/" + Wallpaper.wallpapers.length
        if (mode === "scheme" && Appearance.schemeIndex >= 0)
            return (Appearance.schemeIndex + 1) + "/" + Appearance.schemeNames.length
        return ""
    }

    readonly property color barColor: (mode === "volume" && Audio.muted)
        ? Theme.colors.error : Theme.colors.accent
}
