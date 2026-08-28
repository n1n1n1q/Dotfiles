import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.services.niri

// Transient on-screen display, end-4 style: a pill that drops in below the
// bar (top-centre) whenever volume, brightness or the keyboard layout
// changes, then fades itself out after Theme.popup.osdTimeout. It hangs the
// same Theme.popup.margin below the bar that the dashboard sits off the
// frame, so both read as an equal distance from the frame's top run.
Scope {
    id: root

    // "volume" | "brightness" | "language"
    property string mode: "volume"

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

    // --- Derived display values ------------------------------------------

    readonly property real value: {
        if (mode === "brightness")
            return Brightness.brightness
        if (mode === "volume")
            return Audio.muted ? 0 : Audio.volume
        return 0
    }

    readonly property string icon: {
        if (mode === "brightness")
            return Brightness.getBrightnessIcon()
        if (mode === "language")
            return "󰌌"
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
        return Audio.muted ? "Muted" : "Volume"
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

                // Same drop shadow as the dashboard card.
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -5
                    radius: parent.radius + 5
                    color: Theme.popup.shadow
                    z: -2
                }

                RowLayout {
                    id: contentRow
                    anchors.fill: parent
                    anchors.margins: Theme.popup.padding
                    spacing: Theme.spacing.medium

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: root.icon
                        font.family: Theme.font.icon
                        font.pointSize: Theme.font.xlarge + 4
                        color: Theme.colors.textPrimary
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
                                font.pointSize: Theme.font.small
                                color: Theme.colors.textSecondary
                            }

                            Text {
                                visible: root.mode !== "language"
                                text: Math.round(root.value * 100) + "%"
                                font.family: Theme.font.main
                                font.pointSize: Theme.font.small
                                color: Theme.colors.textSecondary
                            }
                        }

                        // Volume / brightness level - same track/fill as the
                        // dashboard sliders.
                        Rectangle {
                            visible: root.mode !== "language"
                            Layout.fillWidth: true
                            Layout.topMargin: Theme.spacing.tiny
                            Layout.preferredHeight: Theme.sizes.sliderHeight
                            radius: height / 2
                            color: Theme.colors.surface1

                            Rectangle {
                                width: Math.max(0, Math.min(1, root.value)) * parent.width
                                height: parent.height
                                radius: parent.radius
                                color: root.barColor

                                Behavior on width {
                                    NumberAnimation { duration: Theme.animation.fast }
                                }
                            }
                        }

                        // Active keyboard layout
                        Text {
                            visible: root.mode === "language"
                            text: NiriService.keyboardLayoutName
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.large
                            font.weight: Theme.font.mediumWeight
                            color: Theme.colors.textPrimary
                        }
                    }
                }
            }
        }
    }
}
