import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.services.niri
import qs.widgets
import qs.modules.settings

// One cell of the quick-settings grid. `toggleId` picks the behaviour out of
// DashboardConfig's catalogue; `size` decides whether it draws just the glyph
// (one cell) or the glyph plus a name / status line (two cells).
//
// Stateful entries (Wi-Fi, Bluetooth, mute, DND) light up in the accent colour
// while they're on; one-shot actions (screenshot, lock, ...) never do — they
// just flash on press.
Rectangle {
    id: tile

    required property string toggleId
    property string size: "small"
    readonly property bool large: size === "large"

    // Edit mode dims the live state and hands clicks to the editor instead.
    property bool editing: false

    signal activated()

    readonly property var entry: DashboardConfig.toggleEntry(toggleId)
    readonly property bool stateful: ["wifi", "bluetooth", "dnd", "mute", "micMute"]
        .indexOf(toggleId) !== -1

    // --- live state ------------------------------------------------------
    readonly property bool active: {
        switch (toggleId) {
        case "wifi": return WiFi.enabled;
        case "bluetooth": return Bluetooth.enabled;
        case "dnd": return Notifications.doNotDisturb;
        case "mute": return Audio.muted;
        case "micMute": return Audio.sourceMuted;
        }
        return false;
    }

    readonly property bool connected: {
        switch (toggleId) {
        case "wifi": return WiFi.connected;
        case "bluetooth": return Bluetooth.connected;
        }
        return false;
    }

    readonly property string glyph: {
        switch (toggleId) {
        case "wifi": return WiFi.icon;
        case "bluetooth": return Bluetooth.icon;
        case "dnd": return Notifications.doNotDisturb ? "󰂛" : "󰂚";
        case "mute": return Audio.muted ? "󰖁" : "󰕾";
        case "micMute": return Audio.sourceMuted ? "󰍭" : "󰍬";
        }
        return entry.icon;
    }

    // Every glyph this tile can show. The cell that draws it is sized from
    // the whole set rather than from the one on screen, so flipping the toggle
    // can't shove the label beside it sideways — see GlyphIcon.
    readonly property var glyphStates: {
        switch (toggleId) {
        case "wifi": return WiFi.iconStates;
        case "bluetooth": return Bluetooth.iconStates;
        case "dnd": return ["󰂛", "󰂚"];
        case "mute": return Audio.volumeGlyphs;
        case "micMute": return Audio.sourceGlyphs;
        }
        return [entry.icon];
    }

    // Second line on a wide tile — what the thing is actually doing.
    readonly property string detail: {
        switch (toggleId) {
        case "wifi":
            if (!WiFi.enabled) return "Off";
            return WiFi.connected ? WiFi.ssid : "Not connected";
        case "bluetooth":
            if (!Bluetooth.available) return "No adapter";
            if (!Bluetooth.enabled) return "Off";
            return Bluetooth.connected
                ? (Bluetooth.firstConnectedDevice?.name ?? "Connected") : "On";
        case "dnd":
            return Notifications.doNotDisturb ? "Silenced" : "Showing popups";
        case "mute":
            return Audio.muted ? "Muted" : Audio.label(Audio.sink);
        case "micMute":
            return Audio.sourceMuted ? "Muted" : Audio.label(Audio.source);
        }
        return entry.desc ?? "";
    }

    readonly property string label: {
        switch (toggleId) {
        case "wifi": return WiFi.enabled && WiFi.connected ? WiFi.ssid : entry.name;
        case "bluetooth":
            return Bluetooth.connected
                ? (Bluetooth.firstConnectedDevice?.name ?? entry.name) : entry.name;
        }
        return entry.name;
    }

    // A wide tile leads with the network / device name and puts the state
    // underneath; everything else is name over description.
    readonly property string subLabel: {
        switch (toggleId) {
        case "wifi": return WiFi.enabled && WiFi.connected ? "Wi‑Fi" : detail;
        case "bluetooth": return Bluetooth.connected ? "Bluetooth" : detail;
        }
        return detail;
    }

    // --- actions ---------------------------------------------------------
    function run() {
        switch (toggleId) {
        case "wifi": WiFi.toggleWifi(); return true;
        case "bluetooth": Bluetooth.toggleBluetooth(); return true;
        case "dnd": Notifications.toggleDnd(); return true;
        case "mute": Audio.toggleMute(); return true;
        case "micMute": Audio.toggleSourceMute(); return true;
        case "wallpaper": Wallpaper.next(); return true;
        case "screenshot": NiriService.screenshot(); return false;
        case "lock": Quickshell.execDetached(["swaylock"]); return false;
        case "record": Quickshell.execDetached(["wf-recorder"]); return false;
        case "settings": SettingsController.show(); return false;
        case "launcher": LauncherConfig.requestToggle(""); return false;
        }
        return true;
    }

    // --- chrome ----------------------------------------------------------
    readonly property bool lit: active && !editing

    radius: Theme.rounding.huge
    color: lit ? Theme.colors.accent
        : (mouse.pressed ? Theme.colors.borderSubtle
        : (mouse.containsMouse ? Theme.colors.surfaceVariant
        : Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                  Theme.colors.surfaceVariant.b, 0.45)))

    Behavior on color {
        ColorAnimation { duration: Theme.animation.fast; easing.type: Theme.animation.easeOut }
    }

    readonly property color ink: lit ? Theme.colors.bg : Theme.colors.textPrimary

    // Small tile: just the glyph, centred.
    GlyphIcon {
        anchors.centerIn: parent
        visible: !tile.large
        text: tile.glyph
        glyphs: tile.glyphStates
        font.family: Theme.font.icon
        font.pointSize: Theme.font.xlarge + 2
        color: tile.ink
    }

    // Wide tile: glyph + name over status.
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.normal
        anchors.rightMargin: Theme.spacing.small
        visible: tile.large
        spacing: Theme.spacing.small

        GlyphIcon {
            text: tile.glyph
            glyphs: tile.glyphStates
            font.family: Theme.font.icon
            font.pointSize: Theme.font.xlarge + 2
            color: tile.ink
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: tile.label
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.font.normal
                font.weight: Theme.font.mediumWeight
                color: tile.ink
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: tile.subLabel
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.font.tiny
                color: tile.lit
                    ? Qt.rgba(Theme.colors.bg.r, Theme.colors.bg.g, Theme.colors.bg.b, 0.7)
                    : Theme.colors.textTertiary
            }
        }
    }

    // No "connected" dot: both radios already say it in their glyph (signal
    // bars for Wi-Fi, the linked mark for Bluetooth) and a wide tile spells it
    // out underneath.

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: !tile.editing
        hoverEnabled: !tile.editing
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.activated()
    }
}
