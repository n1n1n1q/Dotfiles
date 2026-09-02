import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.services.niri
import qs.widgets

// Transient on-screen display, end-4 style: a pill that drops in below the
// bar (top-centre) whenever volume, brightness or the keyboard layout
// changes, then fades itself out after Theme.popup.osdTimeout. It hangs the
// same Theme.popup.margin below the bar that the dashboard sits off the
// frame, so both read as an equal distance from the frame's top run.
//
// It doubles as the feedback for the wallpaper / colour-scheme keybinds: they
// step through the lists without opening Settings, so the pill is the only
// thing that says what you landed on — hence the thumbnail and the swatch row.
Scope {
    id: root

    // "volume" | "brightness" | "language" | "wallpaper" | "scheme" | "preset" | "dnd"
    property string mode: "volume"

    // Name carried by the last preset-applied signal — the pill's caption in
    // "preset" mode, since by then the config has already moved under it.
    property string presetName: ""

    // Suppress the OSD during startup, when services publish their first
    // values (brightnessctl resolving, pipewire settling, niri reporting the
    // initial layout) - none of those are a user action.
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
        // Only the level OSDs are duplicated there — a wallpaper or scheme
        // swap isn't shown anywhere else, so it always gets its pill.
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

    // Do Not Disturb toggled from a keybind / the dashboard / IPC — the pill is
    // the only confirmation, since the toggle can be flipped from anywhere.
    Connections {
        target: Notifications
        function onDoNotDisturbChanged() { if (root.ready) root.trigger("dnd") }
    }

    // Stepped through from a keybind / IPC. No `ready` gate: these only ever
    // fire on a deliberate step, never while services settle at startup, and
    // picking in Settings goes through `select` / `setScheme` instead — the
    // grid there is its own feedback.
    Connections {
        target: Wallpaper
        function onCycled() { root.trigger("wallpaper") }
    }

    Connections {
        target: Appearance
        function onSchemeCycled() { root.trigger("scheme") }
    }

    // A preset swaps the scheme, fonts, wallpaper and both layouts at once, so
    // the name is the only thing that can usefully be echoed back.
    Connections {
        target: Presets
        function onPresetApplied(name) {
            root.presetName = name
            root.trigger("preset")
        }
    }

    // --- Derived display values ------------------------------------------

    // Volume / brightness draw a 0..1 bar; the stepped modes name a thing
    // instead, so they get a caption line (and a thumbnail / swatches).
    readonly property bool isLevel: mode === "volume" || mode === "brightness"

    // In the icon-inside styles the level bar carries the glyph itself, so
    // the card's own icon column would only say it twice.
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

    // Every glyph `icon` can produce. The column that draws it is sized
    // from the whole set, so stepping through modes — or just turning the
    // volume past a threshold — can't shift the label beside it. See
    // GlyphIcon: these glyphs are drawn wider than the cell they measure.
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

    // The line under the label for every non-level mode.
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

    // Right end of the title row: a percentage for the levels, a position in
    // the list for the things you step through.
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

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:osd"
            exclusiveZone: 0
            color: "transparent"
            mask: Region {} // fully click-through
            // Stays mapped even when idle - toggling a layer-shell window's
            // `visible` rapidly leaves niri remapping it at 0x0. It's
            // transparent + click-through, so an always-on empty strip at the
            // screen top costs nothing; the card itself fades / slides away.
            visible: true

            // Full-width strip below the bar (the bar's exclusive zone drops
            // this window's origin to just under it, exactly like the
            // dashboard), so the card rests the same Theme.popup.margin off
            // the bar that the dashboard sits off the frame.
            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: card.height + Theme.popup.margin * 2

            Rectangle {
                id: card

                x: (parent.width - width) / 2
                y: visState.shown ? Theme.popup.margin : -height
                width: Theme.popup.osdWidth
                height: contentRow.implicitHeight + Theme.popup.padding * 2

                radius: Theme.popup.radius
                color: Theme.popup.background
                border.color: Theme.popup.border
                border.width: Theme.popup.borderWidth
                opacity: visState.shown ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animation.normal
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: Theme.animation.normal
                        easing.type: Easing.OutCubic
                    }
                }

                SoftShadow {}

                RowLayout {
                    id: contentRow
                    anchors.fill: parent
                    anchors.margins: Theme.popup.padding
                    spacing: Theme.spacing.medium

                    // A glyph for every mode but "wallpaper", which puts the
                    // image itself here — seeing what you stepped onto is the
                    // whole point of cycling without the picker.
                    Item {
                        visible: !(root.isLevel && root.iconInside)
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: root.hasThumb ? 54 : glyph.implicitWidth
                        implicitHeight: root.hasThumb ? 32 : glyph.implicitHeight

                        GlyphIcon {
                            id: glyph
                            anchors.centerIn: parent
                            visible: !root.hasThumb
                            text: root.icon
                            glyphs: root.iconStates
                            font.family: Theme.font.icon
                            font.pointSize: Theme.popup.fontXlarge + 4
                            color: Theme.colors.textPrimary
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: root.hasThumb
                            radius: Theme.rounding.small
                            color: Theme.colors.surface1
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: root.hasThumb ? ("file://" + Wallpaper.current) : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                sourceSize.width: 108
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Theme.spacing.tiny

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing.small

                            Text {
                                Layout.fillWidth: true
                                text: root.label
                                elide: Text.ElideRight
                                font.family: Theme.font.main
                                font.pointSize: Theme.popup.fontSmall
                                color: Theme.colors.textSecondary
                            }

                            Text {
                                visible: root.counter.length > 0
                                text: root.counter
                                font.family: Theme.font.main
                                font.pointSize: Theme.popup.fontSmall
                                color: Theme.colors.textSecondary
                            }
                        }

                        // Volume / brightness level - literally the dashboard
                        // slider's own bar, in whichever of its two styles
                        // Settings picked.
                        LevelBar {
                            visible: root.isLevel
                            Layout.fillWidth: true
                            Layout.topMargin: Theme.spacing.tiny
                            value: root.value
                            style: OsdConfig.sliderStyle
                            fillColor: root.barColor
                            icon: root.icon
                            iconColor: Theme.colors.textPrimary
                            // Nothing is dragging this one - the level arrives
                            // already stepped, so it can ease into place.
                            animated: true
                        }

                        // What was landed on: the keyboard layout, the
                        // wallpaper's file name, the scheme's name.
                        Text {
                            visible: !root.isLevel
                            Layout.fillWidth: true
                            text: root.caption
                            elide: Text.ElideMiddle
                            font.family: Theme.font.main
                            font.pointSize: Theme.popup.fontLarge
                            font.weight: Theme.font.mediumWeight
                            color: Theme.colors.textPrimary
                        }

                        // A scheme is judged by its colours, not its name, so
                        // the pill carries an accent strip of the live palette.
                        // A preset carries one too — it just moved the whole
                        // palette along with everything else.
                        Row {
                            visible: root.mode === "scheme" || root.mode === "preset"
                            Layout.topMargin: 2
                            spacing: 4

                            Repeater {
                                model: ["red", "peach", "yellow", "green", "sapphire", "blue", "mauve"]
                                delegate: Rectangle {
                                    required property var modelData
                                    width: 16
                                    height: 8
                                    radius: 2
                                    color: Theme.palette[modelData]
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
