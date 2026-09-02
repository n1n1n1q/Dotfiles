import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.widgets

// Custom-rendered replacement for SystemTrayItem.display()'s native DBusMenu
// popup (unstyled, doesn't match the shell at all). Opened by Tray.qml on
// right-click via PopoutController's "traymenu" card; built from the item's
// DBusMenu tree through QsMenuOpener - see TrayMenuRow for the recursive row.
Rectangle {
    id: root

    // The SystemTrayItem that was right-clicked.
    property var item: null

    // SystemTrayItem.menu is itself the QsMenuHandle the opener wants — feed it
    // straight in (an earlier `.menu.menu` was one hop too far and always came
    // back null, hence the "No actions" bug).
    readonly property var rootHandle: root.item?.menu ?? null

    implicitWidth: 260
    implicitHeight: Math.max(col.implicitHeight, 40) + Theme.spacing.small * 2

    radius: Theme.popup.radius
    color: Theme.popup.background
    border.width: Theme.popup.borderWidth
    border.color: Theme.popup.border

    QsMenuOpener {
        id: opener
        menu: root.rootHandle
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacing.small
        spacing: 1

        Text {
            visible: opener.children.values.length === 0
            Layout.fillWidth: true
            Layout.margins: Theme.spacing.small
            text: "No actions"
            horizontalAlignment: Text.AlignHCenter
            font.family: Theme.font.main
            font.pointSize: Theme.popup.fontSmall
            color: Theme.colors.textTertiary
        }

        Repeater {
            model: opener.children
            delegate: TrayMenuRow {
                required property var modelData
                entry: modelData
            }
        }
    }
}
