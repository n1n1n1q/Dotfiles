import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings
import qs.widgets

// What the drop-down panel is made of: an ordered list of quick-setting tiles
// and an ordered list of sliders. Popup/notification behaviour used to sit at
// the bottom of this page — it now has its own (Settings > Notifications),
// since it is about toasts rather than about the panel.
SettingsPage {
    id: page
    heading: "Dashboard"
    icon: "󰕮"
    blurb: "The panel that drops down from the window title on the left of the "
        + "bar. Turn on edit mode to rearrange it in place: hold a tile and "
        + "drag it onto an insert marker, drop one back on the dock to remove "
        + "it, click a placed tile to resize or restyle it. Layout lives at "
        + "~/.config/quickshell/dashboard.json."

    // --- edit toggle ------------------------------------------------------
    SettingsGroup {
        caption: "Editing"
        icon: "󰙭"

        SettingsRow {
            icon: "󰙭"
            title: "Edit the panel"
            subtitle: "Opens the dashboard with its quick settings and sliders "
                + "in drag-and-drop mode"
            SettingsToggle {
                checked: DashboardConfig.editMode
                onToggled: v => v ? DashboardConfig.beginEdit() : DashboardConfig.commitEdit()
            }
        }
    }

    // --- quick settings ---------------------------------------------------
    SettingsGroup {
        caption: "Quick settings"
        icon: "󰀻"
        hint: DashboardConfig.columns + "-cell grid"

        Note {
            text: "A small tile is one cell and shows only its glyph; a large "
                + "one spans two and adds the name and what it's doing — the "
                + "network it's on, the device it's connected to."
        }

        Repeater {
            model: DashboardConfig.toggles

            delegate: PlacedRow {
                required property var modelData
                required property int index
                kind: "toggles"
                at: index
                total: DashboardConfig.toggles.length
                glyph: DashboardConfig.toggleIcon(modelData.id)
                label: DashboardConfig.toggleName(modelData.id)
                chip: (modelData.size ?? "small") === "large" ? "Large" : "Small"
                onChipClicked: DashboardConfig.cycleToggleSize(index)
            }
        }

        Note {
            visible: DashboardConfig.toggles.length === 0
            text: "No quick settings placed."
        }

        PoolRow {
            label: "Add a quick setting"
            entries: DashboardConfig.availableToggles
            kind: "toggles"
        }
    }

    // --- sliders ----------------------------------------------------------
    SettingsGroup {
        caption: "Sliders"
        icon: "󰕾"
        hint: "right-click one in the panel for its device list"

        Note {
            text: "Each draws as a chunky progress bar, as a handle on a thin "
                + "track, or as a progress bar with its glyph moved inside the "
                + "bar instead of sitting beside it."
        }

        Repeater {
            model: DashboardConfig.sliders

            delegate: PlacedRow {
                required property var modelData
                required property int index
                kind: "sliders"
                at: index
                total: DashboardConfig.sliders.length
                glyph: DashboardConfig.sliderIcon(modelData.id)
                label: DashboardConfig.sliderName(modelData.id)
                chip: DashboardConfig.sliderStyleLabel(modelData.style)
                onChipClicked: DashboardConfig.cycleSliderStyle(index)
            }
        }

        Note {
            visible: DashboardConfig.sliders.length === 0
            text: "No sliders placed."
        }

        PoolRow {
            label: "Add a slider"
            entries: DashboardConfig.availableSliders
            kind: "sliders"
        }
    }

    // --- reset ------------------------------------------------------------
    SettingsGroup {
        caption: "Reset"
        icon: "󰑏"

        SettingsRow {
            icon: "󰑏"
            title: "Reset to default"
            subtitle: "Restore the shipped tiles and sliders — notification "
                + "settings are on their own page and are left alone"
            PillButton {
                text: "Reset"
                danger: true
                onClicked: DashboardConfig.resetLayout()
            }
        }
    }

    // ---------------------------------------------------------------------
    // A dim wrapped line inside a section card — the aside that doesn't fit in
    // the header's one-line hint.
    component Note: Text {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacing.small
        Layout.rightMargin: Theme.spacing.small
        Layout.topMargin: 2
        Layout.bottomMargin: 2
        wrapMode: Text.WordWrap
        font.family: Theme.font.main
        font.pointSize: Theme.font.small
        color: Theme.colors.textTertiary
    }

    // One placed entry: glyph, name, the knob that flips its variant, order
    // arrows and a remove.
    component PlacedRow: RowLayout {
        id: pr
        property string kind: "toggles"
        property int at: 0
        property int total: 0
        property string glyph: ""
        property string label: ""
        property string chip: ""
        signal chipClicked()

        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacing.small
        Layout.rightMargin: Theme.spacing.tiny
        spacing: Theme.spacing.small

        Text {
            text: pr.glyph
            font.family: Theme.font.icon
            font.pointSize: Theme.font.medium
            color: Theme.colors.accent
            Layout.preferredWidth: 22
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: pr.label
            elide: Text.ElideRight
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            color: Theme.colors.textPrimary
        }

        Rectangle {
            implicitWidth: chipLabel.implicitWidth + Theme.spacing.normal * 2
            implicitHeight: 24
            radius: 12
            color: chipMouse.containsMouse ? Theme.colors.accent : Theme.colors.surfaceVariant

            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

            Text {
                id: chipLabel
                anchors.centerIn: parent
                text: pr.chip
                font.family: Theme.font.main
                font.pointSize: Theme.font.tiny
                font.weight: Theme.font.semiBold
                color: chipMouse.containsMouse ? Theme.colors.bg : Theme.colors.textSecondary
            }

            MouseArea {
                id: chipMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: pr.chipClicked()
            }
        }

        MiniBtn {
            glyph: "󰅃"
            dim: pr.at === 0
            onActivated: DashboardConfig.moveAt(pr.kind, pr.at, -1)
        }
        MiniBtn {
            glyph: "󰅀"
            dim: pr.at === pr.total - 1
            onActivated: DashboardConfig.moveAt(pr.kind, pr.at, 1)
        }
        MiniBtn {
            glyph: "󰅖"
            danger: true
            onActivated: DashboardConfig.removeAt(pr.kind, pr.at)
        }
    }

    component MiniBtn: Rectangle {
        id: mb
        property string glyph: ""
        property bool dim: false
        property bool danger: false
        signal activated()

        implicitWidth: 26
        implicitHeight: 24
        radius: Theme.rounding.small
        opacity: dim ? 0.35 : 1
        color: mbMouse.containsMouse && !mb.dim
            ? (mb.danger ? Theme.colors.error : Theme.colors.surfaceVariant)
            : Theme.colors.surface
        border.width: 1
        border.color: Theme.colors.border

        Text {
            anchors.centerIn: parent
            text: mb.glyph
            font.family: Theme.font.icon
            font.pointSize: Theme.font.small
            color: mbMouse.containsMouse && !mb.dim && mb.danger
                ? Theme.colors.bg
                : (mb.danger ? Theme.colors.error : Theme.colors.textSecondary)
        }

        MouseArea {
            id: mbMouse
            anchors.fill: parent
            enabled: !mb.dim
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mb.activated()
        }
    }

    // Everything not placed yet — click one to append it to the panel.
    component PoolRow: ColumnLayout {
        id: pool
        property string label: ""
        property string kind: "toggles"
        property var entries: []

        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacing.small
        Layout.rightMargin: Theme.spacing.small
        Layout.topMargin: Theme.spacing.tiny
        spacing: Theme.spacing.tiny
        visible: entries.length > 0

        Text {
            text: pool.label
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            color: Theme.colors.textTertiary
        }

        Flow {
            Layout.fillWidth: true
            spacing: Theme.spacing.tiny

            Repeater {
                model: pool.entries

                delegate: Rectangle {
                    id: chip
                    required property var modelData

                    implicitWidth: chipRow.implicitWidth + Theme.spacing.normal * 2
                    implicitHeight: 30
                    radius: Theme.rounding.small
                    color: chipM.containsMouse ? Theme.colors.surfaceVariant : Theme.colors.bg
                    border.width: 1
                    border.color: Theme.colors.border

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: Theme.spacing.tiny

                        Text {
                            text: "󰐕"
                            font.family: Theme.font.icon
                            font.pointSize: Theme.font.small
                            color: Theme.colors.accent
                        }
                        Text {
                            text: chip.modelData.name
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.small
                            color: Theme.colors.textPrimary
                        }
                    }

                    MouseArea {
                        id: chipM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DashboardConfig.add(pool.kind, chip.modelData.id)
                    }
                }
            }
        }
    }
}
