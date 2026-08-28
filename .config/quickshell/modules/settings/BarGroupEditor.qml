import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings

// Editor card for one bar group: a background toggle, group move/delete
// controls, its ordered widget list, and an inline "add widget" picker.
Rectangle {
    id: root

    required property string section     // "left" | "center" | "right"
    required property int groupIndex
    required property var group
    required property int groupCount

    property bool picking: false
    readonly property var widgetIds: group.widgets ?? []

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + Theme.spacing.normal * 2
    radius: Theme.workspace.indicatorRadius
    color: Theme.colors.surface

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacing.normal
        spacing: Theme.spacing.small

        // --- header ------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small

            Text {
                text: "Group " + (root.groupIndex + 1)
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                font.weight: Theme.font.semiBold
                font.capitalization: Font.AllUppercase
                color: Theme.colors.textTertiary
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Background"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textSecondary
            }
            SettingsToggle {
                checked: root.group.background ?? false
                onToggled: checked => BarConfig.setGroupBackground(root.section, root.groupIndex, checked)
            }

            // pin to region centre
            IconButton {
                icon: "󰐃"
                readonly property bool pinned: root.group.pin ?? false
                highlighted: pinned
                onClicked: BarConfig.setGroupPin(root.section, root.groupIndex, !pinned)
            }

            IconButton {
                icon: "󰅃"
                enabledButton: root.groupIndex > 0
                onClicked: BarConfig.moveGroup(root.section, root.groupIndex, -1)
            }
            IconButton {
                icon: "󰅀"
                enabledButton: root.groupIndex < root.groupCount - 1
                onClicked: BarConfig.moveGroup(root.section, root.groupIndex, 1)
            }
            IconButton {
                icon: "󰩹"
                danger: true
                onClicked: BarConfig.removeGroup(root.section, root.groupIndex)
            }
        }

        // --- widgets in this group -------------------------------------------
        Repeater {
            model: root.widgetIds

            delegate: Rectangle {
                id: wRow
                required property var modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: 40
                radius: Theme.rounding.small
                color: Theme.colors.surfaceVariant

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacing.normal
                    anchors.rightMargin: Theme.spacing.tiny
                    spacing: Theme.spacing.small

                    Text {
                        text: BarConfig.widgetIcon(wRow.modelData)
                        font.family: Theme.font.icon
                        font.pointSize: Theme.font.medium
                        color: Theme.colors.textSecondary
                    }
                    Text {
                        Layout.fillWidth: true
                        text: BarConfig.widgetName(wRow.modelData)
                        elide: Text.ElideRight
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.small
                        color: Theme.colors.textPrimary
                    }

                    IconButton {
                        icon: "󰅃"
                        enabledButton: wRow.index > 0
                        onClicked: BarConfig.moveWidget(root.section, root.groupIndex, wRow.index, -1)
                    }
                    IconButton {
                        icon: "󰅀"
                        enabledButton: wRow.index < root.widgetIds.length - 1
                        onClicked: BarConfig.moveWidget(root.section, root.groupIndex, wRow.index, 1)
                    }
                    IconButton {
                        icon: "󰅖"
                        danger: true
                        onClicked: BarConfig.removeWidget(root.section, root.groupIndex, wRow.index)
                    }
                }
            }
        }

        Text {
            visible: root.widgetIds.length === 0
            text: "Empty group — add a widget below."
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            color: Theme.colors.textTertiary
        }

        // --- add widget ----------------------------------------------------
        PillButton {
            text: root.picking ? "Close" : "＋ Add widget"
            onClicked: root.picking = !root.picking
        }

        WidgetPicker {
            visible: root.picking
            onPicked: id => {
                BarConfig.addWidget(root.section, root.groupIndex, id);
                root.picking = false;
            }
        }
    }
}
