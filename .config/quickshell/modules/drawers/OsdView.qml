pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.modules.osd
import qs.widgets

// The OSD pill for one screen — a card that drops in below the bar and fades
// out after a timeout. Hosted by the Drawers window; state comes from a shared
// OsdLogic. Was the PanelWindow body of Osd.qml.
Item {
    id: root
    anchors.fill: parent

    required property OsdLogic logic

    // The OSD only ever drops from the top edge; inset past a top-docked bar.
    readonly property real topInset: (BarConfig.edge === "top" && !BarConfig.floating)
        ? Theme.bar.height
        : (BarConfig.edge === "top" ? Theme.bar.height + Theme.bar.margin : 0)

    // Exposed so the Drawers window can add the card to its input mask (though
    // the card is click-through in practice — kept for parity with the old
    // per-window Region).
    readonly property alias card: card

    Rectangle {
        id: card

        x: Math.round((root.width - width) / 2)
        y: root.logic.shown ? root.topInset + Theme.popup.margin : -height
        width: Theme.popup.osdWidth
        height: contentRow.implicitHeight + Theme.popup.padding * 2

        radius: Theme.popup.radius
        color: Theme.popup.background
        border.color: Theme.popup.border
        border.width: Theme.popup.borderWidth
        opacity: root.logic.shown ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
            NumberAnimation { duration: Theme.animation.normal; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            NumberAnimation { duration: Theme.animation.normal; easing.type: Easing.OutCubic }
        }

        SoftShadow {}

        RowLayout {
            id: contentRow
            anchors.fill: parent
            anchors.margins: Theme.popup.padding
            spacing: Theme.spacing.medium

            Item {
                visible: !(root.logic.isLevel && root.logic.iconInside)
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: root.logic.hasThumb ? 54 : glyph.implicitWidth
                implicitHeight: root.logic.hasThumb ? 32 : glyph.implicitHeight

                GlyphIcon {
                    id: glyph
                    anchors.centerIn: parent
                    visible: !root.logic.hasThumb
                    text: root.logic.icon
                    glyphs: root.logic.iconStates
                    font.family: Theme.font.icon
                    font.pointSize: Theme.popup.fontXlarge + 4
                    color: Theme.colors.textPrimary
                }

                Rectangle {
                    anchors.fill: parent
                    visible: root.logic.hasThumb
                    radius: Theme.rounding.small
                    color: Theme.colors.surface1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.logic.hasThumb ? ("file://" + Wallpaper.current) : ""
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
                        text: root.logic.label
                        elide: Text.ElideRight
                        font.family: Theme.font.main
                        font.pointSize: Theme.popup.fontSmall
                        color: Theme.colors.textSecondary
                    }

                    Text {
                        visible: root.logic.counter.length > 0
                        text: root.logic.counter
                        font.family: Theme.font.main
                        font.pointSize: Theme.popup.fontSmall
                        color: Theme.colors.textSecondary
                    }
                }

                LevelBar {
                    visible: root.logic.isLevel
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing.tiny
                    value: root.logic.value
                    style: OsdConfig.sliderStyle
                    fillColor: root.logic.barColor
                    icon: root.logic.icon
                    iconColor: Theme.colors.textPrimary
                    animated: true
                }

                Text {
                    visible: !root.logic.isLevel
                    Layout.fillWidth: true
                    text: root.logic.caption
                    elide: Text.ElideMiddle
                    font.family: Theme.font.main
                    font.pointSize: Theme.popup.fontLarge
                    font.weight: Theme.font.mediumWeight
                    color: Theme.colors.textPrimary
                }

                Row {
                    visible: root.logic.mode === "scheme" || root.logic.mode === "preset"
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
