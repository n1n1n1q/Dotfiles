import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.modules.settings

// Output and input in one card each — the level control sits on top of the list
// of devices it's driving, so picking a sink and setting its volume is one
// place, not two sections apart. Per-app streams get the same control below.
SettingsPage {
    id: page
    heading: "Sound"
    icon: "󰕾"
    blurb: "Output and input devices, levels and per-app volume — via PipeWire."

    // A speaker vs. headphone guess from the active sink's name, so the level
    // control's glyph matches what you're actually listening on.
    function sinkGlyph(node) {
        const s = (Audio.label(node) + " " + (node?.name ?? "")).toLowerCase();
        if (s.includes("headphone") || s.includes("headset") || s.includes("hands-free"))
            return "󰋋";
        if (s.includes("hdmi") || s.includes("displayport") || s.includes("display port"))
            return "󰡁";
        if (s.includes("bluetooth") || s.includes("bluez"))
            return "󰥰";
        return "󰓃";
    }

    // One selectable device in a sink/source list.
    component DeviceRow: SettingsRow {
        id: dr
        required property var node
        property var current: null
        property string kind: "󰓃"
        readonly property bool selected: current === node
        compact: true
        hoverable: true
        icon: selected ? "󰄬" : dr.kind
        title: Audio.label(node)
        subtitle: node.description && node.description !== Audio.label(node)
            ? node.description : node.name

        Text {
            visible: dr.selected
            text: "Active"
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            font.weight: Theme.font.semiBold
            color: Theme.colors.accent
        }
    }

    // --- output ------------------------------------------------------------
    SettingsGroup {
        caption: "Output"
        icon: "󰕾"
        hint: Audio.label(Audio.sink)

        VolumeControl {
            icon: page.sinkGlyph(Audio.sink)
            title: "Volume"
            subtitle: Audio.muted ? "Muted" : Audio.label(Audio.sink)
            value: Audio.volume
            muted: Audio.muted
            onMoved: v => Audio.setVolume(v)
            onMuteToggled: Audio.toggleMute()
        }

        Repeater {
            model: Audio.sinks.length > 1 ? Audio.sinks : []
            delegate: DeviceRow {
                required property var modelData
                node: modelData
                current: Audio.sink
                kind: page.sinkGlyph(modelData)
                onClicked: Audio.setAudioSink(modelData)
            }
        }
    }

    // --- input -----------------------------------------------------------------
    SettingsGroup {
        caption: "Input"
        icon: "󰍬"
        hint: Audio.label(Audio.source)

        VolumeControl {
            icon: "󰍬"
            title: "Microphone"
            subtitle: Audio.sourceMuted ? "Muted" : Audio.label(Audio.source)
            value: Audio.sourceVolume
            muted: Audio.sourceMuted
            accent: Theme.colors.success
            onMoved: v => Audio.setSourceVolume(v)
            onMuteToggled: Audio.toggleSourceMute()
        }

        Repeater {
            model: Audio.sources.length > 1 ? Audio.sources : []
            delegate: DeviceRow {
                required property var modelData
                node: modelData
                current: Audio.source
                kind: "󰍬"
                onClicked: Audio.setAudioSource(modelData)
            }
        }
    }

    // --- per-app mixer -----------------------------------------------------
    SettingsGroup {
        caption: "Applications"
        icon: "󰀻"
        hint: Audio.streams.length > 0
            ? Audio.streams.length + (Audio.streams.length === 1 ? " stream" : " streams")
            : ""

        Repeater {
            model: Audio.streams
            delegate: VolumeControl {
                required property var modelData
                icon: Audio.nodeIcon(modelData)
                title: Audio.label(modelData)
                subtitle: modelData.properties?.["media.name"] ?? ""
                value: modelData.audio?.volume ?? 0
                muted: modelData.audio?.muted ?? false
                onMoved: v => { if (modelData.audio) { modelData.audio.muted = false; modelData.audio.volume = v; } }
                onMuteToggled: { if (modelData.audio) modelData.audio.muted = !modelData.audio.muted; }
            }
        }

        SettingsRow {
            visible: Audio.streams.length === 0
            icon: "󰝛"
            title: "Nothing playing"
            subtitle: "Apps that are playing audio show up here with their own level"
        }
    }
}
