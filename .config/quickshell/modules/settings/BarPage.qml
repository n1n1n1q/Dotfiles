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
    blurb: "The bar is groups of widgets in three regions. Rearrange it in the "
        + "full-screen editor, tune each widget below, and style the frame it "
        + "sits in. Layout lives at ~/.config/quickshell/bar.json."

    property bool layoutOpen: false
    property bool inactiveOpen: false

    // ============================================================
    //  1 · Layout — the editor toggle + an inline group arranger
    // ============================================================
    SettingsGroup {
        caption: "Layout"
        icon: "󰕮"

        SettingsRow {
            icon: "󰙭"
            title: "Edit the bar"
            subtitle: "Opens the full-screen editor — hold-drag widgets between "
                + "the bar and the pool, drop one back on the pool to remove it"
            SettingsToggle {
                checked: BarConfig.editMode
                onToggled: v => v ? BarConfig.beginEdit() : BarConfig.commitEdit()
            }
        }

        SettingsRow {
            icon: "󱇈"
            title: "Arrange groups"
            subtitle: "Per-group background, centre pin and delete, across the "
                + "left / centre / right regions"
            hoverable: true
            onClicked: page.layoutOpen = !page.layoutOpen
            Text {
                text: page.layoutOpen ? "󰅃" : "󰅀"
                font.family: Theme.font.icon
                font.pointSize: Theme.font.medium
                color: Theme.colors.textTertiary
            }
        }

        // The three lanes, revealed by "Arrange groups".
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacing.small
            Layout.topMargin: page.layoutOpen ? Theme.spacing.tiny : 0
            spacing: Theme.spacing.small
            visible: page.layoutOpen

            LaneView { section: "left";   label: "Left";   groups: BarConfig.left }
            LaneView { section: "center"; label: "Centre"; groups: BarConfig.center }
            LaneView { section: "right";  label: "Right";  groups: BarConfig.right }
        }
    }

    // ============================================================
    //  2 · Widget settings — one drawer per widget on the bar,
    //      with the rest tucked into an "inactive" section
    // ============================================================
    SettingsGroup {
        caption: "Widget settings"
        icon: "󰒓"
        hint: "config is kept even when a widget is off the bar"

        Repeater {
            model: page._configurable(BarConfig.activeWidgetIds)
            delegate: WidgetConfig {
                required property var modelData
                wid: modelData
            }
        }

        SettingsRow {
            visible: page._configurable(BarConfig.activeWidgetIds).length === 0
            icon: "󰝦"
            title: "No configurable widgets on the bar"
            subtitle: "Widgets with options light up here once they're placed"
        }

        // --- inactive drawer ---------------------------------------
        SettingsRow {
            visible: page._inactiveConfigurable().length > 0
            icon: "󰘓"
            title: "Widgets not on the bar"
            subtitle: page._inactiveConfigurable().length
                + (page._inactiveConfigurable().length === 1 ? " widget" : " widgets")
                + " — their settings are still here"
            hoverable: true
            onClicked: page.inactiveOpen = !page.inactiveOpen
            Text {
                text: page.inactiveOpen ? "󰅃" : "󰅀"
                font.family: Theme.font.icon
                font.pointSize: Theme.font.medium
                color: Theme.colors.textTertiary
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacing.small
            spacing: Theme.spacing.tiny
            visible: page.inactiveOpen

            Repeater {
                model: page.inactiveOpen ? page._inactiveConfigurable() : []
                delegate: WidgetConfig {
                    required property var modelData
                    wid: modelData
                    inactive: true
                }
            }
        }
    }

    // ============================================================
    //  3 · Style — bar / frame appearance
    // ============================================================
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

    // ------------------------------------------------------------------
    //  helpers
    // ------------------------------------------------------------------
    function _configurable(ids) {
        return (ids ?? []).filter(id => (BarConfig.widget(id).settings ?? []).length > 0);
    }
    function _inactiveConfigurable() {
        const active = BarConfig.activeWidgetIds;
        return BarConfig.catalogue
            .filter(c => (c.settings ?? []).length > 0 && active.indexOf(c.id) === -1)
            .map(c => c.id);
    }

    // ------------------------------------------------------------------
    //  one widget's collapsible settings drawer
    // ------------------------------------------------------------------
    component WidgetConfig: ColumnLayout {
        id: wc
        property string wid: ""
        property bool inactive: false
        readonly property var cat: BarConfig.widget(wid)
        readonly property var schema: cat.settings ?? []
        property bool open: false

        Layout.fillWidth: true
        spacing: Theme.spacing.tiny

        // header
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 46
            radius: Theme.rounding.large
            color: hdrHover.hovered ? Theme.palette.surface2
                : Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                          Theme.colors.surfaceVariant.b, wc.inactive ? 0.35 : 0.55)
            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

            HoverHandler { id: hdrHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: wc.open = !wc.open
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing.medium
                anchors.rightMargin: Theme.spacing.medium
                spacing: Theme.spacing.small

                Text {
                    text: wc.cat.icon
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.large
                    color: wc.inactive ? Theme.colors.textTertiary : Theme.colors.textSecondary
                }
                Text {
                    Layout.fillWidth: true
                    text: wc.cat.name
                    elide: Text.ElideRight
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.medium
                    color: wc.inactive ? Theme.colors.textSecondary : Theme.colors.textPrimary
                }
                Text {
                    text: wc.schema.length + (wc.schema.length === 1 ? " option" : " options")
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.small
                    color: Theme.colors.textTertiary
                }
                Text {
                    text: wc.open ? "󰅃" : "󰅀"
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.medium
                    color: Theme.colors.textTertiary
                }
            }
        }

        // body
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacing.medium
            spacing: Theme.spacing.tiny
            visible: wc.open

            Repeater {
                model: wc.open ? wc.schema : []
                delegate: SettingsRow {
                    id: optRow
                    required property var modelData
                    readonly property var val: BarConfig.widgetSetting(wc.wid, modelData.key)
                    compact: modelData.type !== "mediaLayout"
                    title: modelData.label

                    SettingsToggle {
                        visible: optRow.modelData.type === "toggle"
                        checked: optRow.val === true
                        onToggled: v => BarConfig.setWidgetSetting(wc.wid, optRow.modelData.key, v)
                    }
                    SettingsSpin {
                        visible: optRow.modelData.type === "spin"
                        from: optRow.modelData.min ?? 0
                        to: optRow.modelData.max ?? 100
                        step: optRow.modelData.step ?? 1
                        suffix: optRow.modelData.suffix ?? ""
                        value: optRow.modelData.type === "spin" ? optRow.val : 0
                        onStepped: v => BarConfig.setWidgetSetting(wc.wid, optRow.modelData.key, v)
                    }
                    MediaLayoutPicker {
                        visible: optRow.modelData.type === "mediaLayout"
                        labels: false
                        value: optRow.modelData.type === "mediaLayout" ? optRow.val : "regular"
                        onPicked: v => BarConfig.setWidgetSetting(wc.wid, optRow.modelData.key, v)
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------
    //  group arranger (unchanged mechanics, just lives inside "Layout")
    // ------------------------------------------------------------------
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
}
