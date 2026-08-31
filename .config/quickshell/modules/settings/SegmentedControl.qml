import QtQuick
import QtQuick.Layouts
import qs.config

// A run of choice pills — the selected one fills with the accent, the rest sit
// on the row's surface. `options` is an array of
// { value, label, icon } (label and icon both optional).
RowLayout {
    id: root

    property var options: []
    property var value: undefined
    // Icon-only pills, for when the glyph says it all.
    property bool iconOnly: false
    signal picked(var value)

    spacing: Theme.spacing.tiny

    Repeater {
        model: root.options

        delegate: Rectangle {
            id: seg
            required property var modelData
            readonly property bool on: root.value === modelData.value
            readonly property bool hasLabel: !root.iconOnly
                && (modelData.label ?? "").length > 0

            implicitWidth: segRow.implicitWidth + (hasLabel ? Theme.spacing.medium
                                                            : Theme.spacing.small) * 2
            implicitHeight: 28
            radius: height / 2
            color: on ? Theme.colors.accent
                : segMouse.containsMouse ? Theme.colors.surfaceVariant
                : Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                          Theme.colors.surfaceVariant.b, 0.5)

            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

            RowLayout {
                id: segRow
                anchors.centerIn: parent
                spacing: Theme.spacing.tiny

                Text {
                    visible: (seg.modelData.icon ?? "").length > 0
                    text: seg.modelData.icon ?? ""
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.medium
                    color: seg.on ? Theme.colors.bg : Theme.colors.textSecondary
                }

                Text {
                    visible: seg.hasLabel
                    text: seg.modelData.label ?? ""
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.small
                    font.weight: seg.on ? Theme.font.mediumWeight : Theme.font.regular
                    color: seg.on ? Theme.colors.bg : Theme.colors.textPrimary
                }
            }

            MouseArea {
                id: segMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(seg.modelData.value)
            }
        }
    }
}
