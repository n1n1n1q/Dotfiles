import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.modules.settings
import qs.widgets

SettingsPage {
    id: page
    heading: "Bar"
    icon: "󰟀"
    blurb: "Turn on edit mode to rearrange the bar: a full-screen editor opens "
        + "with the bar and a widget pool. Hold a widget and drag it onto an "
        + "insert marker; drop one back on the pool to remove it. Enter saves, "
        + "Esc cancels. Layout lives at ~/.config/quickshell/bar.json."

    // --- edit toggle ----------------------------------------------------
    SettingsGroup {
        caption: "Editing"
        icon: "󰙭"

        SettingsRow {
            icon: "󰙭"
            title: "Edit the bar"
            subtitle: "Opens the full-screen layout editor — hold-drag widgets "
                + "from the pool onto the bar, drop them back to remove."
            SettingsToggle {
                checked: BarConfig.editMode
                onToggled: v => v ? BarConfig.beginEdit() : BarConfig.commitEdit()
            }
        }
    }

    // --- bar / frame style --------------------------------------------
    SettingsGroup {
        caption: "Style"
        icon: "󰏘"
        dense: true
        SettingsRow {
            icon: "󰍹"
            title: "Position"
            subtitle: "Screen edge the bar docks to — left / right make it vertical"
            SegmentedControl {
                iconOnly: true
                value: BarConfig.edge
                options: [
                    { value: "top",    icon: "󱂥" },
                    { value: "bottom", icon: "󱂣" },
                    { value: "left",   icon: "󱂤" },
                    { value: "right",  icon: "󱂦" }
                ]
                onPicked: v => BarConfig.setStyle("edge", v)
            }
        }
        SettingsRow {
            icon: "󰹖"
            title: "Floating bar"
            subtitle: "Detach the bar into a pill inset from the screen edges "
                + "(turns the screen frame off)"
            SettingsToggle {
                checked: BarConfig.floating
                onToggled: v => BarConfig.setStyle("floating", v)
            }
        }
        SettingsRow {
            icon: "󰝤"
            title: "Floating corners"
            subtitle: "Round the floating pill's own corners"
            opacity: BarConfig.floating ? 1 : 0.4
            SettingsToggle {
                enabled: BarConfig.floating
                checked: BarConfig.floatRounded
                onToggled: v => BarConfig.setStyle("floatRounded", v)
            }
        }
        SettingsRow {
            icon: "󰄨"
            title: "Screen frame"
            subtitle: BarConfig.floating
                ? "Unavailable while the bar is floating"
                : "The thin border decoration along the screen edges"
            opacity: BarConfig.floating ? 0.4 : 1
            SettingsToggle {
                enabled: !BarConfig.floating
                checked: BarConfig.frameEnabled
                onToggled: v => BarConfig.setStyle("frame", v)
            }
        }
        SettingsRow {
            icon: "󰟥"
            title: "Rounded corners"
            subtitle: "Round the corner transitions — with or without the frame"
            opacity: BarConfig.floating ? 0.4 : 1
            SettingsToggle {
                enabled: !BarConfig.floating
                checked: BarConfig.frameRounded
                onToggled: v => BarConfig.setStyle("rounded", v)
            }
        }
        SettingsRow {
            icon: "󰓃"
            title: "Black corners"
            subtitle: "The black screen-rounder accents in each corner"
            SettingsToggle {
                checked: BarConfig.blackCorners
                onToggled: v => BarConfig.setStyle("blackCorners", v)
            }
        }
    }

    // --- popout cards ---------------------------------------------------
    SettingsGroup {
        caption: "Popouts"
        icon: "󰝚"
        SettingsRow {
            icon: "󰝚"
            title: "Now-playing layout"
            subtitle: "Layout of the media card — a disc one spins while playing"
            MediaLayoutPicker {
                value: BarConfig.mediaLayout
                onPicked: v => BarConfig.setPopout("mediaLayout", v)
            }
        }
    }

    // --- layout view (per-group + future per-widget config) -----------
    SectionHeader {
        Layout.topMargin: Theme.spacing.tiny
        title: "Layout"
        icon: "󰕮"
        hint: "left · centre · right"
    }

    component MiniToggle: Rectangle {
        id: mt
        property string glyph: ""
        property bool on: false
        property color tint: Theme.colors.textSecondary
        signal act()
        width: 26
        height: 24
        radius: height / 2
        color: mt.on ? Theme.colors.accent
            : (mtMouse.containsMouse ? Theme.colors.surfaceVariant
               : Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                         Theme.colors.surfaceVariant.b, 0.5))
        Text {
            anchors.centerIn: parent
            text: mt.glyph
            font.family: Theme.font.icon
            font.pointSize: Theme.font.small
            color: mt.on ? Theme.colors.bg : mt.tint
        }
        MouseArea {
            id: mtMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mt.act()
        }
    }

    component LaneView: ColumnLayout {
        id: lane
        required property string section
        required property string label
        required property var groups
        Layout.fillWidth: true
        spacing: Theme.spacing.tiny

        SettingsCaption {
            text: lane.label
        }

        Repeater {
            model: lane.groups
            delegate: Rectangle {
                id: groupCard
                required property var modelData
                required property int index
                readonly property var widgetIds: modelData.widgets ?? []
                Layout.fillWidth: true
                implicitHeight: gcCol.implicitHeight + Theme.spacing.normal * 2
                radius: Theme.rounding.huge
                color: Theme.colors.surface

                ColumnLayout {
                    id: gcCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spacing.normal }
                    spacing: Theme.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.small
                        Text {
                            Layout.fillWidth: true
                            text: "Group " + (groupCard.index + 1)
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.small
                            font.weight: Theme.font.semiBold
                            color: Theme.colors.textSecondary
                        }
                        MiniToggle {
                            glyph: "󰝤"; on: groupCard.modelData.background ?? false
                            onAct: BarConfig.setGroupBackground(lane.section, groupCard.index, !(groupCard.modelData.background ?? false))
                        }
                        MiniToggle {
                            // pinning only makes sense for the centre region
                            visible: lane.section === "center"
                            glyph: "󰐃"; on: groupCard.modelData.pin ?? false
                            onAct: BarConfig.setGroupPin(lane.section, groupCard.index, !(groupCard.modelData.pin ?? false))
                        }
                        MiniToggle {
                            glyph: "󰅖"; tint: Theme.colors.error
                            onAct: BarConfig.removeGroup(lane.section, groupCard.index)
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.tiny
                        Repeater {
                            model: groupCard.widgetIds
                            delegate: Rectangle {
                                id: wchip
                                required property var modelData
                                required property int index
                                implicitWidth: wcRow.implicitWidth + Theme.spacing.small * 2
                                implicitHeight: 26
                                radius: Theme.rounding.small
                                color: Theme.colors.surfaceVariant
                                RowLayout {
                                    id: wcRow
                                    anchors.centerIn: parent
                                    spacing: Theme.spacing.tiny
                                    Text {
                                        text: BarConfig.widgetIcon(wchip.modelData)
                                        font.family: Theme.font.icon
                                        font.pointSize: Theme.font.small
                                        color: Theme.colors.textSecondary
                                    }
                                    Text {
                                        text: BarConfig.widgetName(wchip.modelData)
                                        font.family: Theme.font.main
                                        font.pointSize: Theme.font.small
                                        color: Theme.colors.textPrimary
                                    }
                                    // future: per-widget settings
                                    Text {
                                        text: "󰒓"
                                        font.family: Theme.font.icon
                                        font.pointSize: Theme.font.tiny
                                        color: Theme.colors.textTertiary
                                        opacity: 0.5
                                        ToolTip.visible: cogHover.hovered
                                        ToolTip.text: "Per-widget settings coming soon"
                                        HoverHandler { id: cogHover }
                                    }
                                    Text {
                                        text: "󰅖"
                                        font.family: Theme.font.icon
                                        font.pointSize: Theme.font.tiny
                                        color: Theme.colors.textTertiary
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: BarConfig.removeWidget(lane.section, groupCard.index, wchip.index)
                                        }
                                    }
                                }
                            }
                        }
                        Text {
                            visible: groupCard.widgetIds.length === 0
                            text: "empty"
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.tiny
                            color: Theme.colors.textTertiary
                        }
                    }
                }
            }
        }
    }

    LaneView { section: "left";   label: "Left";   groups: BarConfig.left }
    LaneView { section: "center"; label: "Centre"; groups: BarConfig.center }
    LaneView { section: "right";  label: "Right";  groups: BarConfig.right }

    // --- reset ----------------------------------------------------------
    SettingsGroup {
        caption: "Reset"
        icon: "󰑏"

        SettingsRow {
            icon: "󰑏"
            title: "Reset to default"
            subtitle: "Restore the shipped left / centre / right layout"
            PillButton {
                text: "Reset"
                danger: true
                onClicked: BarConfig.reset()
            }
        }
    }
}
