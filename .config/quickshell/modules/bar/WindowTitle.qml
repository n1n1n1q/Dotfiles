import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services.niri

// Left-of-bar focused-window label, and the dashboard toggle (replaced the
// old gear ConfigButton). Two stacked lines with a tight negative leading
// (end-4's ActiveWindow.qml pattern): the app id small/dim on top, the window
// title bigger below. Text colour is static; hovering just fades in a subtle
// background behind the block. Clicking anywhere opens / toggles the
// dashboard panel for this screen (shell.qml's DashboardLayer owns the
// windows; this just asks the one on our own output to toggle).
Item {
    id: root

    property var parentWindow: null
    property real barHeight: 50

    readonly property int hPad: Theme.spacing.normal
    readonly property int maxTextWidth: 440
    readonly property string appId: NiriService.activeWindowAppId
    readonly property string title: NiriService.activeWindowTitle

    implicitWidth: bg.width
    implicitHeight: barHeight

    Rectangle {
        id: bg

        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(col.implicitWidth, root.maxTextWidth) + root.hPad * 2
        // match the workspace capsule / other bar modules' hover pill
        height: Theme.workspace.indicatorHeight
        radius: Theme.workspace.indicatorRadius

        color: mouse.containsMouse ? Theme.colors.hover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

        ColumnLayout {
            id: col

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: root.hPad
            anchors.rightMargin: root.hPad
            spacing: -2

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.appId || "Desktop"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                font.weight: Theme.font.regular
                color: Theme.colors.textTertiary
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.title
                    || ("Workspace " + (NiriService.focusedWorkspace?.idx ?? 1))
                font.family: Theme.font.main
                font.pointSize: Theme.font.large
                font.weight: Theme.font.semiBold
                color: Theme.colors.textPrimary
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: DashboardConfig.requestToggle(root.parentWindow?.screen?.name ?? "")
    }
}
