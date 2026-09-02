import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.config
import qs.widgets
import qs.modules.popout

// System tray on the bar's right edge - one icon per StatusNotifierItem, no
// background. Left-click activates the item (or opens its menu if it's
// menu-only); right-click (or a left-click on a menu-only item) opens a
// custom-themed dropdown built from the item's DBusMenu (TrayMenuCard) via
// the same bar-popout mechanism as the calendar/media/system-monitor cards —
// SystemTrayItem.display()'s native menu looked completely unstyled. Scroll
// is forwarded to the item.
RowLayout {
    id: root

    property string screenName: ""

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
                    PopoutController.close()
                    modelData.activate()
                } else if (modelData.hasMenu) {
                    const p = entry.mapToItem(null, entry.width / 2, 0)
                    PopoutController.toggle("traymenu", p.x, entry.width, root.screenName, modelData)
                }
            }
            onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)

            IconImage {
                anchors.fill: parent
                // Synchronous on purpose: a themed SNI icon (e.g. nm-applet's
                // "network-wired", which resolves to an SVG) loaded on the async
                // image thread crashes Qt's SVG icon engine on startup
                // (QIcon::pixmap → QPixmap::load, not thread-safe). These icons
                // are tiny and few, so the GUI-thread load is cheap.
                asynchronous: false
                source: entry.modelData.icon
                opacity: entry.containsMouse ? 1.0 : 0.85
                Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }
            }

            AppTooltip {
                id: tip
                visible: entry.containsMouse && text.length > 0
                delay: 500
                text: entry.modelData.tooltipTitle || entry.modelData.title || entry.modelData.id || ""
            }
        }
    }
}
