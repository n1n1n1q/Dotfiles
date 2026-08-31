pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root
    
        // Get all available audio nodes and categorize them
    readonly property var nodes: {
        const allNodes = Pipewire.nodes.values;
        const result = {
            sinks: [],
            sources: [],
            streams: []
        };

        for (let i = 0; i < allNodes.length; i++) {
            const node = allNodes[i];
            if (node.isStream) {
                // Application playback streams (app -> speakers).
                if (node.audio && node.isSink)
                    result.streams.push(node);
            } else if (node.isSink) {
                result.sinks.push(node);
            } else if (node.audio && !(node.name || "").endsWith(".monitor")) {
                // Real capture devices, not loopback monitors.
                result.sources.push(node);
            }
        }

        return result;
    }

    readonly property var sinks: nodes.sinks
    readonly property var sources: nodes.sources
    // Per-application playback streams, for the per-app mixer.
    readonly property var streams: nodes.streams

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // Bind all audio nodes so we can read their properties
    PwObjectTracker {
        objects: [...root.sinks, ...root.sources, ...root.streams, sink, source].filter(node => node != null)
    }

    // Friendly label for a node (app name / description / name).
    function label(node) {
        if (!node)
            return "";
        const p = node.properties ?? ({});
        return p["application.name"] || node.description || node.nickname || node.name || "Unknown";
    }
    function nodeIcon(node) {
        const p = node?.properties ?? ({});
        const n = ((p["application.name"] || node?.name || "") + " " + (p["application.icon-name"] || "")).toLowerCase();
        if (n.includes("firefox") || n.includes("zen")) return "󰈹";
        if (n.includes("chrom")) return "󰊯";
        if (n.includes("mpv") || n.includes("vlc") || n.includes("video")) return "󰐌";
        if (n.includes("spotify")) return "󰓇";
        if (n.includes("discord")) return "󰙯";
        if (n.includes("telegram")) return "󰔁";
        if (n.includes("music") || n.includes("audacious") || n.includes("player")) return "󰝚";
        return "󰝚";
    }
    
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    
    // Every glyph the shell draws for the sink and the source. An icon cell
    // sized from the whole set keeps its width when the level or the mute
    // changes state, instead of dragging its neighbours along with it — see
    // GlyphIcon for why a Nerd-Font glyph's width is not its advance.
    readonly property var volumeGlyphs: ["󰝟", "󰖁", "󰕿", "󰖀", "󰕾"]
    readonly property var sourceGlyphs: ["󰍭", "󰍬", "󰍮"]
    
    readonly property real sourceVolume: source?.audio?.volume ?? 0
    readonly property bool sourceMuted: source?.audio?.muted ?? false
    
    // Maximum volume limit (configurable, 1.0 = 100%)
    readonly property real maxVolume: 1.0
    
    // Volume control functions
    function setVolume(newVolume) {
        if (sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(maxVolume, newVolume));
        }
    }
    
    function incrementVolume(amount = 0.05) {
        setVolume(volume + amount);
    }
    
    function decrementVolume(amount = 0.05) {
        setVolume(volume - amount);
    }
    
    function toggleMute() {
        if (sink?.audio) {
            sink.audio.muted = !sink.audio.muted;
        }
    }
    
    // Source volume control functions
    function setSourceVolume(newVolume) {
        if (source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(maxVolume, newVolume));
        }
    }
    
    function incrementSourceVolume(amount = 0.05) {
        setSourceVolume(sourceVolume + amount);
    }
    
    function decrementSourceVolume(amount = 0.05) {
        setSourceVolume(sourceVolume - amount);
    }
    
    function toggleSourceMute() {
        if (source?.audio) {
            source.audio.muted = !source.audio.muted;
        }
    }
    
    // Device switching functions
    function setAudioSink(newSink) {
        Pipewire.preferredDefaultAudioSink = newSink;
    }
    
    function setAudioSource(newSource) {
        Pipewire.preferredDefaultAudioSource = newSource;
    }
    
    Component.onCompleted: {
        console.log("Audio service initialized");
        console.log("Total sinks:", sinks.length);
        console.log("Total sources:", sources.length);
        for (let i = 0; i < sinks.length; i++) {
            console.log("  Sink", i, ":", sinks[i].description || sinks[i].name);
        }
        for (let i = 0; i < sources.length; i++) {
            console.log("  Source", i, ":", sources[i].description || sources[i].name);
        }
    }
}
