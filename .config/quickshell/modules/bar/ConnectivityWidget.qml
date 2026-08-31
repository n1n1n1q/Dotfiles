import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets
import qs.modules.settings

// One compact block of three live connectivity glyphs — Wi‑Fi, Bluetooth,
// sound. Each glyph reacts to its service (signal strength, BT state, volume /
// mute). The block is one hover target with a single wash; clicking anywhere
// opens Settings on the General page.
Item {
    id: root

    implicitWidth: row.implicitWidth + hPad * 2
    implicitHeight: Theme.workspace.indicatorHeight

    readonly property int hPad: Theme.spacing.medium

    Rectangle {
        anchors.fill: parent
        radius: Theme.workspace.indicatorRadius
        color: mouse.containsMouse ? Theme.colors.hover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
    }

    // A live glyph — no interaction of its own; the whole block is one target.
    // Each one is sized from every glyph its service can hand it, so the block
    // keeps its width (and the bar keeps its layout) as the states change.
    component ConnIcon: GlyphIcon {
        Layout.alignment: Qt.AlignVCenter
        font.family: Theme.font.icon
        font.pointSize: Theme.bar.fontSizeLarge + 3
        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spacing.large

        ConnIcon {
            glyphs: WiFi.iconStates
            text: WiFi.icon
            color: !WiFi.enabled ? Theme.colors.textTertiary
                : WiFi.connected ? Theme.colors.textPrimary
                : Theme.colors.textSecondary
        }

        ConnIcon {
            glyphs: Bluetooth.iconStates
            text: Bluetooth.icon
            color: !Bluetooth.available || !Bluetooth.enabled ? Theme.colors.textTertiary
                : Bluetooth.connected ? Theme.colors.accent
                : Theme.colors.textSecondary
        }

        ConnIcon {
            glyphs: Audio.volumeGlyphs
            text: {
                if (Audio.muted || Audio.volume <= 0) return "󰝟"        // volume-mute
                if (Audio.volume < 0.34) return "󰕿"                      // volume-low
                if (Audio.volume < 0.67) return "󰖀"                      // volume-medium
                return "󰕾"                                               // volume-high
            }
            color: Audio.muted ? Theme.colors.error
                : Audio.volume <= 0 ? Theme.colors.textTertiary
                : Theme.colors.textPrimary
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SettingsController.show("wifi")
    }
}
