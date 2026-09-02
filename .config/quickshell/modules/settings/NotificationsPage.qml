import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings
import qs.widgets

// The two transient overlays: the toasts that slide in from a screen corner,
// and the pill that drops under the bar for volume / brightness. They used to
// be scattered across Dashboard and General; they live together here because
// they are the same kind of thing — something the shell shows you for a moment
// and takes away again.
//
// Both blocks are persisted elsewhere (dashboard.json's `notifications`, and
// osd.json) — this page is only their editor.
SettingsPage {
    id: page
    heading: "Notifications"
    icon: "󰎟"
    blurb: "Where toasts appear and how long they keep their close button, plus "
        + "the on-screen display that shows volume and brightness."

    // --- popups ----------------------------------------------------------
    SettingsGroup {
        caption: "Popups"
        icon: "󰎟"

        SettingsRow {
            icon: "󰎟"
            title: "Popup corner"
            subtitle: "Where toasts slide in — bottom corners stack upwards"
            // Drawn rather than glyphed: a little screen with the toast
            // sitting in the corner it would appear in.
            RowLayout {
                spacing: Theme.spacing.tiny
                Repeater {
                    model: ["top-left", "top-right", "bottom-left", "bottom-right"]

                    delegate: Rectangle {
                        id: cornerTile
                        required property string modelData
                        readonly property bool on: DashboardConfig.notifCorner === modelData
                        readonly property bool atTop: modelData.indexOf("top") === 0
                        readonly property bool atLeft: modelData.indexOf("left") > 0

                        implicitWidth: 38
                        implicitHeight: 28
                        radius: Theme.rounding.medium
                        color: on ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g,
                                            Theme.colors.accent.b, 0.22)
                            : (cm.containsMouse ? Theme.colors.surfaceVariant
                               : Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                                         Theme.colors.surfaceVariant.b, 0.5))

                        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                        Rectangle {
                            width: 14
                            height: 7
                            radius: 2
                            color: cornerTile.on ? Theme.colors.accent : Theme.colors.textTertiary
                            x: cornerTile.atLeft ? 5 : cornerTile.width - width - 5
                            y: cornerTile.atTop ? 5 : cornerTile.height - height - 5
                        }

                        MouseArea {
                            id: cm
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DashboardConfig.setNotif("corner", cornerTile.modelData)
                        }
                    }
                }
            }
        }

        SettingsRow {
            icon: "󱂷"
            title: "Group by source"
            subtitle: DashboardConfig.notifGrouped
                ? "Each app collapses into one stack you can drop open"
                : "Every notification gets its own card, newest first"
            SettingsToggle {
                checked: DashboardConfig.notifGrouped
                onToggled: v => DashboardConfig.setNotif("grouping", v ? "source" : "off")
            }
        }

        SettingsRow {
            icon: "󰅖"
            title: "Close button delay"
            subtitle: "How long the pointer rests on a notification before its "
                + "close button fades in"
            RowLayout {
                spacing: Theme.spacing.tiny
                Repeater {
                    model: [
                        { ms: 0,   name: "Instant" },
                        { ms: 350, name: "Short" },
                        { ms: 800, name: "Long" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool on: DashboardConfig.notifCloseDelay === modelData.ms
                        implicitWidth: delayLabel.implicitWidth + Theme.spacing.normal * 2
                        implicitHeight: 28
                        radius: height / 2
                        color: on ? Theme.colors.accent
                            : (dm.containsMouse ? Theme.colors.surfaceVariant
                               : Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                                         Theme.colors.surfaceVariant.b, 0.5))
                        Text {
                            id: delayLabel
                            anchors.centerIn: parent
                            text: modelData.name
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.small
                            color: parent.on ? Theme.colors.bg : Theme.colors.textPrimary
                        }
                        MouseArea {
                            id: dm
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DashboardConfig.setNotif("closeDelay", parent.modelData.ms)
                        }
                    }
                }
            }
        }
    }

    // --- on-screen display -----------------------------------------------
    SettingsGroup {
        caption: "On-screen display"
        icon: "󰕾"
        hint: "volume & brightness"

        SettingsRow {
            icon: "󰈈"
            title: "Level bar style"
            subtitle: "Now a single shell-wide choice — set it in "
                + "Settings › Appearance › Slider style"
            LevelBar {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 180
                Layout.preferredHeight: implicitHeight
                value: 0.65
                style: Appearance.sliderStyle
                icon: "󰕾"
                animated: true
            }
        }
    }

}
