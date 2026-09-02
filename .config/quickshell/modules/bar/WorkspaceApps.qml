pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.config
import qs.services
import qs.services.niri
import qs.widgets
import qs.modules.popout

// A fixed-width strip of the app icons on this output's current workspace — a
// "what's in here" companion to WorkspaceIndicator's "which workspace".
//
// The widget is a fixed number of equal slots (as many as `width` fits). The
// running apps sit in the middle slots; any slot they don't reach shows a
// faint placeholder dot, so a half-used widget still reads as a deliberate
// shape rather than a stray cluster. Once there are more apps than slots the
// dots disappear and the row scrolls to keep the active window's icon in view.
// Click an icon to focus that window.
Item {
    id: root

    required property string outputName

    readonly property int fixedWidth: Math.max(24, BarConfig.widgetSetting("workspaceApps", "width"))
    readonly property int iconSize: BarConfig.widgetSetting("workspaceApps", "iconSize")
    readonly property real stride: iconSize + Theme.spacing.small

    readonly property var ws: NiriService.activeWorkspaceForOutput(outputName)
    readonly property var wins: ws ? NiriService.windowsForWorkspace(ws.id) : []
    readonly property int activeIdx:
        wins.findIndex(w => w.id === (ws?.active_window_id ?? -1))

    // How many icon slots span the fixed width, and whether the apps overrun them.
    readonly property int capacity: Math.max(1, Math.floor((fixedWidth + Theme.spacing.small) / stride))
    readonly property bool overflow: wins.length > capacity

    // One entry per rendered cell: `{ win }` for an app, `{ win: null }` for a
    // placeholder dot. While the apps fit, `capacity` cells with the apps
    // centred; once they overrun, just the apps (the row itself scrolls).
    readonly property var cells: {
        if (root.overflow)
            return wins.map(w => ({ win: w }));
        const start = Math.floor((capacity - wins.length) / 2);
        const out = [];
        for (let i = 0; i < capacity; i++) {
            const ai = i - start;
            out.push({ win: (ai >= 0 && ai < wins.length) ? wins[ai] : null });
        }
        return out;
    }

    implicitWidth: fixedWidth
    implicitHeight: Theme.workspace.indicatorHeight
    clip: true

    Row {
        id: iconRow

        height: parent.height
        spacing: Theme.spacing.small

        // Centred while everything fits; once overflowing, scroll so the active
        // window's icon stays on screen (centre it, then clamp so no empty
        // space shows past either end).
        x: {
            const contentW = iconRow.implicitWidth;
            if (!root.overflow || contentW <= root.width)
                return Math.round((root.width - contentW) / 2);
            if (root.activeIdx < 0)
                return 0;
            const c = root.activeIdx * root.stride + root.iconSize / 2;
            return Math.round(Math.max(root.width - contentW,
                                       Math.min(0, root.width / 2 - c)));
        }
        Behavior on x { NumberAnimation { duration: Theme.animation.normal; easing.type: Easing.OutCubic } }

        Repeater {
            model: root.cells

            delegate: Item {
                id: cell

                required property var modelData
                readonly property var win: modelData.win
                readonly property bool focused:
                    !!win && win.id === (root.ws?.active_window_id ?? -1)

                width: root.iconSize
                height: root.iconSize
                anchors.verticalCenter: parent.verticalCenter

                // Placeholder for a slot with no app.
                Rectangle {
                    anchors.centerIn: parent
                    visible: !cell.win
                    width: Math.max(3, Math.round(root.iconSize * 0.16))
                    height: width
                    radius: width / 2
                    color: Theme.colors.textTertiary
                    opacity: 0.45
                }

                IconImage {
                    anchors.fill: parent
                    visible: !!cell.win
                    // Synchronous: themed icons resolve through Qt's SVG icon
                    // engine, which is not thread-safe (see Tray.qml).
                    asynchronous: false
                    source: cell.win ? Apps.iconForClass(cell.win.app_id) : ""
                    opacity: mouse.containsMouse ? 1
                        : cell.focused ? 1 : 0.55
                    Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }
                }

                // Focused-window marker, echoing the workspace puck's accent.
                Rectangle {
                    visible: cell.focused
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 1
                    width: parent.width * 0.55
                    height: 2
                    radius: 1
                    color: Theme.colors.accent
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    // Eat the gap either side too, so there's no dead strip
                    // between icons.
                    anchors.leftMargin: -Math.round(Theme.spacing.small / 2)
                    anchors.rightMargin: -Math.round(Theme.spacing.small / 2)
                    enabled: !!cell.win
                    hoverEnabled: !!cell.win
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        PopoutController.close();
                        if (cell.win)
                            NiriService.focusWindow(cell.win.id);
                    }
                }

                AppTooltip {
                    visible: mouse.containsMouse && text.length > 0
                    delay: 500
                    text: cell.win ? (cell.win.title || cell.win.app_id || "") : ""
                }
            }
        }
    }
}
