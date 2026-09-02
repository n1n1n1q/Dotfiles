import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.widgets

// One configured slider row. `sliderId` picks what it drives out of
// DashboardConfig's catalogue; `style` is one of DashboardConfig.sliderStyles,
// and widgets/LevelBar draws whichever it names. The only thing the row itself
// has to know about the choice is whether the bar has taken the glyph inside
// it, which drops the icon column and widens the bar to fill the row.
//
// There is no dropdown arrow any more: right-clicking the row opens the device
// list for the sliders that have one (volume / microphone). Clicking the glyph
// mutes.
ColumnLayout {
    id: root

    required property string sliderId
    property string style: "progress"
    property bool editing: false

    readonly property var entry: DashboardConfig.sliderEntry(sliderId)
    readonly property bool iconInside:
        DashboardConfig.sliderStyleEntry(style).iconInside === true
    property bool expanded: false

    Layout.fillWidth: true
    spacing: Theme.spacing.tiny

    // --- what this row drives --------------------------------------------
    readonly property real value: {
        switch (sliderId) {
        case "volume": return Audio.volume;
        case "microphone": return Audio.sourceVolume;
        case "brightness": return Brightness.brightness;
        }
        return 0;
    }
    readonly property bool muted: {
        switch (sliderId) {
        case "volume": return Audio.muted;
        case "microphone": return Audio.sourceMuted;
        }
        return false;
    }
    readonly property string glyph: {
        switch (sliderId) {
        case "volume": return Audio.muted ? "󰖁" : "󰕾";
        case "microphone":
            return Audio.sourceMuted ? "󰍭" : (Audio.sourceVolume > 0.5 ? "󰍬" : "󰍮");
        case "brightness": return Brightness.getBrightnessIcon();
        }
        return entry.icon;
    }
    // Every glyph this row can show, so the icon column keeps one width as
    // the level moves and the mute flips — see GlyphIcon.
    readonly property var glyphStates: {
        switch (sliderId) {
        case "volume": return Audio.volumeGlyphs;
        case "microphone": return Audio.sourceGlyphs;
        case "brightness": return Brightness.iconStates;
        }
        return [entry.icon];
    }
    // Shared by the icon column and the inline copy inside the bar. A level
    // slider's glyph isn't a "success" state — it's neutral at rest, accent
    // while the row is open, error only when the channel is muted.
    readonly property color glyphColor: muted ? Theme.colors.error
        : (expanded ? Theme.colors.accent : Theme.colors.textSecondary)
    readonly property var devices: {
        switch (sliderId) {
        case "volume": return Audio.sinks;
        case "microphone": return Audio.sources;
        }
        return [];
    }
    readonly property var currentDevice: {
        switch (sliderId) {
        case "volume": return Audio.sink;
        case "microphone": return Audio.source;
        }
        return null;
    }
    readonly property bool hasMenu: entry.menu === true && devices.length > 0

    function apply(v) {
        switch (sliderId) {
        case "volume": Audio.setVolume(v); return;
        case "microphone": Audio.setSourceVolume(v); return;
        case "brightness": Brightness.setBrightness(v); return;
        }
    }
    function mute() {
        switch (sliderId) {
        case "volume": Audio.toggleMute(); return;
        case "microphone": Audio.toggleSourceMute(); return;
        }
    }
    function pick(device) {
        switch (sliderId) {
        case "volume": Audio.setAudioSink(device); return;
        case "microphone": Audio.setAudioSource(device); return;
        }
    }

    onExpandedChanged: if (expanded && !hasMenu) expanded = false

    // --- the row ----------------------------------------------------------
    Item {
        id: rowBody
        Layout.fillWidth: true
        implicitHeight: row.implicitHeight + Theme.padding.small * 2

        Rectangle {
            anchors.fill: parent
            radius: Theme.rounding.large
            color: rowHover.hovered ? Qt.rgba(Theme.colors.surfaceVariant.r,
                                              Theme.colors.surfaceVariant.g,
                                              Theme.colors.surfaceVariant.b, 0.35)
                : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
        }

        HoverHandler { id: rowHover }

        RowLayout {
            id: row
            anchors.fill: parent
            anchors.margins: Theme.padding.small
            spacing: Theme.spacing.normal

            // Beside the bar in every style but "inline", which moves this
            // same glyph into the bar's leading end.
            GlyphIcon {
                visible: !root.iconInside
                text: root.glyph
                glyphs: root.glyphStates
                font.family: Theme.font.icon
                font.pointSize: Theme.dashboard.fontXlarge
                color: root.glyphColor
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 32

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    enabled: !root.editing && root.entry.menu === true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.mute()
                }
            }

            Slider {
                id: slider

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                enabled: !root.editing
                from: 0
                to: 1
                value: root.value
                stepSize: 0.01
                wheelEnabled: true

                onMoved: root.apply(value)

                // Track, fill and handle all come out of LevelBar, so this
                // row and the OSD pill are one control in two places.
                background: LevelBar {
                    id: bar
                    x: slider.leftPadding
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: slider.availableWidth
                    height: implicitHeight
                    value: slider.visualPosition
                    style: root.style
                    fillColor: root.muted ? Theme.colors.error : Theme.colors.accent
                    handleColor: slider.pressed ? Theme.colors.accentAlt : Theme.colors.text
                    icon: root.glyph
                    iconColor: root.glyphColor
                }

                // The inline glyph is still the mute button it was out in the
                // icon column: it takes the press before the Slider sees it,
                // so the leading end of the bar mutes rather than dragging the
                // level down to zero.
                MouseArea {
                    x: bar.x
                    y: bar.y
                    width: bar.iconExtent
                    height: bar.height
                    enabled: !root.editing && root.iconInside && root.entry.menu === true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.mute()
                }

                // The handle is drawn by the background; this is the spacer
                // the Slider measures it by — it maps the pointer across
                // availableWidth minus the handle, and both styles keep that
                // width so the feel doesn't change with the look.
                handle: Item {
                    implicitWidth: Theme.sizes.levelHandle
                    implicitHeight: Theme.sizes.levelHandle
                }
            }
        }

        // Right-click anywhere on the row opens / closes the device list. Only
        // the right button is accepted, so left-drags still reach the slider.
        MouseArea {
            anchors.fill: parent
            enabled: !root.editing && root.hasMenu
            acceptedButtons: Qt.RightButton
            onClicked: root.expanded = !root.expanded
        }
    }

    // --- device list (right-click) ----------------------------------------
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: root.expanded ? deviceCard.implicitHeight : 0
        visible: Layout.preferredHeight > 0
        clip: true
        opacity: root.expanded ? 1 : 0

        Behavior on Layout.preferredHeight {
            NumberAnimation { duration: Theme.animation.normal; easing.type: Theme.animation.easingInOut }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.animation.normal; easing.type: Theme.animation.easingInOut }
        }

        Rectangle {
            id: deviceCard
            width: parent.width
            implicitHeight: deviceCol.implicitHeight + Theme.padding.normal * 2
            height: implicitHeight
            radius: Theme.rounding.normal
            color: Theme.colors.surface1

            ColumnLayout {
                id: deviceCol
                anchors { left: parent.left; right: parent.right; top: parent.top
                          margins: Theme.padding.normal }
                spacing: Theme.spacing.tiny

                Repeater {
                    model: root.devices

                    delegate: Rectangle {
                        id: dev
                        required property var modelData
                        readonly property bool isActive: root.currentDevice?.id === modelData.id

                        Layout.fillWidth: true
                        implicitHeight: Theme.sizes.buttonLarge - 6
                        radius: Theme.rounding.small
                        color: isActive ? Theme.colors.accent
                            : (devMouse.containsMouse ? Theme.colors.surfaceVariant : Theme.colors.surface)

                        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.padding.normal
                            anchors.rightMargin: Theme.padding.normal
                            spacing: Theme.spacing.small

                            Text {
                                text: dev.isActive ? "󰄬" : "󰝥"
                                font.family: Theme.font.icon
                                font.pointSize: Theme.dashboard.fontMedium
                                color: dev.isActive ? Theme.colors.bg : Theme.colors.accent
                            }

                            Text {
                                Layout.fillWidth: true
                                text: Audio.label(dev.modelData)
                                elide: Text.ElideMiddle
                                font.family: Theme.font.main
                                font.pointSize: Theme.dashboard.fontSmall
                                color: dev.isActive ? Theme.colors.bg : Theme.colors.textPrimary
                            }
                        }

                        MouseArea {
                            id: devMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pick(dev.modelData)
                        }
                    }
                }
            }
        }
    }
}
