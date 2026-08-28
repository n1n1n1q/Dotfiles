import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.config

// System tray on the bar's right edge - one icon per StatusNotifierItem, no
// background. Left-click activates the item (or opens its menu if it's
// menu-only); right-click always opens the item's own menu (rendered natively
// via Quickshell's SystemTrayItem.display); scroll is forwarded to the item.
RowLayout {
    id: root

    spacing: Theme.spacing.normal + 1

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: entry

            required property SystemTrayItem modelData

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Theme.bar.iconSize
            implicitHeight: Theme.bar.iconSize

            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                    modelData.activate()
                } else if (modelData.hasMenu) {
                    const p = entry.mapToItem(null, 0, entry.height)
                    modelData.display(entry.QsWindow.window, p.x, p.y)
                }
            }
            onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)

            IconImage {
                anchors.fill: parent
                asynchronous: true
                source: entry.modelData.icon
                opacity: entry.containsMouse ? 1.0 : 0.85
                Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }
            }

            ToolTip.visible: containsMouse && ToolTip.text.length > 0
            ToolTip.delay: 500
            ToolTip.text: modelData.tooltipTitle || modelData.title || modelData.id || ""
        }
    }
}
