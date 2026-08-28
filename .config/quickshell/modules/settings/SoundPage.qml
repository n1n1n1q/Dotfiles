import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.modules.settings

SettingsPage {
    id: page
    heading: "Sound"
    blurb: "Output and input devices, levels and per-app volume — via PipeWire."

    component DeviceRow: SettingsRow {
        id: dr
        required property var node
        property var current: null
        property string kind: "󰕾"
        readonly property bool selected: current === node
        hoverable: true
        icon: selected ? "󰄬" : dr.kind
        title: Audio.label(node)
        subtitle: node.description && node.description !== Audio.label(node) ? node.description : node.name

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

        VolumeControl {
            icon: "󰕾"
            title: "Volume"
            subtitle: Audio.label(Audio.sink)
            value: Audio.volume
            muted: Audio.muted
            onMoved: v => Audio.setVolume(v)
            onMuteToggled: Audio.toggleMute()
        }
    }

    SettingsGroup {
        caption: "Output device"
        visible: Audio.sinks.length > 0

        Repeater {
            model: Audio.sinks
            delegate: DeviceRow {
                required property var modelData
                node: modelData
                current: Audio.sink
                onClicked: Audio.setAudioSink(modelData)
            }
        }
    }

    // --- input -----------------------------------------------------------------
    SettingsGroup {
        caption: "Input"

        VolumeControl {
            icon: "󰍬"
            title: "Microphone"
            subtitle: Audio.label(Audio.source)
            value: Audio.sourceVolume
            muted: Audio.sourceMuted
            accent: Theme.colors.success
            onMoved: v => Audio.setSourceVolume(v)
            onMuteToggled: Audio.toggleSourceMute()
        }
    }

    SettingsGroup {
        caption: "Input device"
        visible: Audio.sources.length > 0

        Repeater {
            model: Audio.sources
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
        caption: "App volume"
        visible: Audio.streams.length > 0

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
    }

    Text {
        visible: Audio.streams.length === 0
        Layout.leftMargin: Theme.spacing.tiny
        text: "Nothing is playing audio right now."
        font.family: Theme.font.main
        font.pointSize: Theme.font.small
        color: Theme.colors.textTertiary
    }
}
