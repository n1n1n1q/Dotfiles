import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.config
import qs.modules.settings

SettingsPage {
    id: page
    heading: "Widgets"
    icon: "󰀻"
    blurb: "Widgets that live on the desktop. Turn on edit mode to drag them "
        + "into place (hold Shift while dragging to snap to a grid and to "
        + "alignment guides). Saved to ~/.config/quickshell/desktop.json."

    // "all" + every connected output
    readonly property var screenOptions: {
        let n = ["all"];
        for (const s of Quickshell.screens) n.push(s.name);
        return n;
    }
    function screenLabel(v) { return v === "all" ? "All displays" : v; }
    property string addScreen: screenOptions.length > 1 ? screenOptions[1] : "all"

    // --- edit mode -------------------------------------------------------
    SettingsGroup {
        SettingsRow {
            icon: "󰙭"
            title: "Edit layout"
            subtitle: "Drag to move, drag a corner to resize, hold Shift to snap. "
                + "Enter saves · Esc cancels · switching workspace cancels."
            SettingsToggle {
                checked: DesktopConfig.editMode
                onToggled: v => v ? DesktopConfig.beginEdit() : DesktopConfig.commitEdit()
            }
        }
    }

    // --- add ------------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: "Add a widget"
            font.family: Theme.font.main
            font.pointSize: Theme.font.medium
            font.weight: Theme.font.semiBold
            color: Theme.colors.textSecondary
        }
        Text {
            text: "Target"
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            color: Theme.colors.textTertiary
        }
        ComboBox {
            Layout.preferredWidth: 190
            model: page.screenOptions
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            displayText: page.screenLabel(currentText)
            delegate: ItemDelegate {
                width: parent ? parent.width : 0
                text: page.screenLabel(modelData)
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
            }
            Component.onCompleted: currentIndex = Math.max(0, page.screenOptions.indexOf(page.addScreen))
            onActivated: page.addScreen = currentText
        }
    }

    DesktopWidgetPalette {
        Layout.fillWidth: true
        targetScreen: page.addScreen
    }

    // --- placed widgets -----------------------------------------------
    Text {
        text: "Placed widgets"
        font.family: Theme.font.main
        font.pointSize: Theme.font.medium
        font.weight: Theme.font.semiBold
        color: Theme.colors.textSecondary
    }

    SettingsRow {
        visible: DesktopConfig.widgets.length === 0
        icon: "󰝦"
        title: "Nothing placed yet"
        subtitle: "Add a widget above, then turn on Edit layout to position it"
    }

    Repeater {
        model: DesktopConfig.widgets

        delegate: Rectangle {
            id: card
            required property var modelData
            readonly property var cat: DesktopConfig.catalogueEntry(modelData.type)
            readonly property var p: modelData.props ?? ({})

            Layout.fillWidth: true
            implicitHeight: cardCol.implicitHeight + Theme.spacing.normal * 2
            radius: Theme.workspace.indicatorRadius
            color: Theme.colors.surface

            ColumnLayout {
                id: cardCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacing.normal
                spacing: Theme.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.normal

                    Rectangle {
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: Theme.rounding.small
                        color: Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g,
                                       Theme.colors.accent.b, 0.16)
                        Text {
                            anchors.centerIn: parent
                            text: card.cat.icon
                            font.family: Theme.font.icon
                            font.pointSize: Theme.font.large
                            color: Theme.colors.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: card.cat.name
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.medium
                            font.weight: Theme.font.mediumWeight
                            color: Theme.colors.textPrimary
                        }
                        Text {
                            text: page.screenLabel(card.modelData.screen) + "  ·  "
                                + Math.round(card.modelData.x) + ", " + Math.round(card.modelData.y)
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.small
                            color: Theme.colors.textTertiary
                        }
                    }

                    ComboBox {
                        Layout.preferredWidth: 160
                        model: page.screenOptions
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.small
                        displayText: page.screenLabel(currentText)
                        delegate: ItemDelegate {
                            width: parent ? parent.width : 0
                            text: page.screenLabel(modelData)
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.small
                        }
                        Component.onCompleted: currentIndex = Math.max(0, page.screenOptions.indexOf(card.modelData.screen))
                        onActivated: DesktopConfig.setScreen(card.modelData.id, currentText)
                    }

                    PillButton {
                        text: "Remove"
                        danger: true
                        onClicked: DesktopConfig.remove(card.modelData.id)
                    }
                }

                // per-type props
                Flow {
                    Layout.fillWidth: true
                    Layout.leftMargin: 44
                    spacing: Theme.spacing.small

                    component Chip: Rectangle {
                        id: chip
                        property string label: ""
                        property bool on: false
                        signal toggled()
                        implicitWidth: chipT.implicitWidth + Theme.spacing.normal * 2
                        implicitHeight: 26
                        radius: Theme.rounding.small
                        color: chip.on ? Theme.colors.accent : Theme.colors.surfaceVariant
                        Text {
                            id: chipT
                            anchors.centerIn: parent
                            text: chip.label
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.small
                            color: chip.on ? Theme.colors.bg : Theme.colors.textSecondary
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: chip.toggled()
                        }
                    }

                    // clock
                    Chip {
                        visible: card.modelData.type === "clock"
                        label: "24-hour"; on: card.p.format24 ?? true
                        onToggled: DesktopConfig.setProp(card.modelData.id, "format24", !(card.p.format24 ?? true))
                    }
                    Chip {
                        visible: card.modelData.type === "clock"
                        label: "Show date"; on: card.p.showDate ?? true
                        onToggled: DesktopConfig.setProp(card.modelData.id, "showDate", !(card.p.showDate ?? true))
                    }
                    Repeater {
                        model: card.modelData.type === "clock" ? ["left", "center", "right"] : []
                        delegate: Chip {
                            required property string modelData
                            label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                            on: (card.p.align ?? "center") === modelData
                            onToggled: DesktopConfig.setProp(card.modelData.id, "align", modelData)
                        }
                    }

                    // stats
                    Chip {
                        visible: card.modelData.type === "stats"
                        label: "CPU"; on: card.p.showCpu ?? true
                        onToggled: DesktopConfig.setProp(card.modelData.id, "showCpu", !(card.p.showCpu ?? true))
                    }
                    Chip {
                        visible: card.modelData.type === "stats"
                        label: "RAM"; on: card.p.showRam ?? true
                        onToggled: DesktopConfig.setProp(card.modelData.id, "showRam", !(card.p.showRam ?? true))
                    }
                    Chip {
                        visible: card.modelData.type === "stats"
                        label: "GPU"; on: card.p.showGpu ?? false
                        onToggled: DesktopConfig.setProp(card.modelData.id, "showGpu", !(card.p.showGpu ?? false))
                    }

                    // size (all types)
                    RowLayout {
                        spacing: 2
                        readonly property string key: card.modelData.type === "clock" ? "fontScale" : "scale"
                        readonly property real val: card.p[key] ?? 1.0
                        Text {
                            text: "Size"
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.small
                            color: Theme.colors.textTertiary
                        }
                        Repeater {
                            model: [{ g: "−", d: -0.1 }, { g: "+", d: 0.1 }]
                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: 24; implicitHeight: 24
                                radius: Theme.rounding.small
                                color: szMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.g
                                    font.family: Theme.font.main
                                    font.pointSize: Theme.font.large
                                    color: Theme.colors.textSecondary
                                }
                                MouseArea {
                                    id: szMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const nv = Math.max(0.5, Math.min(2.5,
                                            Math.round((parent.parent.val + modelData.d) * 10) / 10));
                                        DesktopConfig.setProp(card.modelData.id, parent.parent.key, nv);
                                    }
                                }
                            }
                        }
                        Text {
                            text: Math.round((card.p[parent.key] ?? 1.0) * 100) + "%"
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.small
                            font.features: ({ "tnum": 1 })
                            color: Theme.colors.textSecondary
                        }
                    }
                }
            }
        }
    }
}
