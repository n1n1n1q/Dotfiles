pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.widgets

// The little right-click menu on an app row: pin to / unpin from favourites,
// and hide the app from the launcher entirely. Rolled by hand — the shell
// doesn't theme QtQuick.Controls menus (cf. modules/bar TrayMenuCard).
//
// The host (LauncherWindow) positions it at the click point and flips `open`;
// it calls straight into LauncherConfig and asks to be dismissed afterwards.
Item {
    id: root

    property string appId: ""
    property bool open: false

    signal dismissed()

    anchors.fill: parent
    visible: open
    z: 100

    readonly property bool fav: LauncherConfig.isFavorite(appId)

    // Catch clicks anywhere else and close.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.dismissed()
    }

    Rectangle {
        id: menu

        // Placed by the host via `x` / `y` on the root; clamp inside the card.
        x: Math.max(Theme.spacing.small,
            Math.min(root._px, root.width - width - Theme.spacing.small))
        y: Math.max(Theme.spacing.small,
            Math.min(root._py, root.height - height - Theme.spacing.small))

        implicitWidth: 210
        implicitHeight: col.implicitHeight + Theme.spacing.small * 2
        radius: Theme.rounding.control
        color: Theme.popup.background
        border.width: 1
        border.color: Theme.colors.hairline

        SoftShadow { spread: 16 }

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Theme.spacing.small
            spacing: 0

            component Entry: Rectangle {
                id: e
                property string glyph: ""
                property string label: ""
                property bool danger: false
                signal triggered()
                width: parent.width
                height: 34
                radius: Theme.rounding.small
                color: eMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacing.small
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacing.small
                    Text {
                        text: e.glyph
                        font.family: Theme.font.icon
                        font.pointSize: Theme.font.medium
                        color: e.danger ? Theme.colors.error : Theme.colors.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: e.label
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.small
                        color: e.danger ? Theme.colors.error : Theme.colors.textPrimary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: eMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: e.triggered()
                }
            }

            Entry {
                glyph: root.fav ? "󰐀" : "󰐃"
                label: root.fav ? "Unpin from favourites" : "Pin to favourites"
                onTriggered: {
                    LauncherConfig.toggleFavorite(root.appId);
                    root.dismissed();
                }
            }

            Entry {
                glyph: "󰈉"
                label: "Hide from launcher"
                danger: true
                onTriggered: {
                    LauncherConfig.toggleHidden(root.appId);
                    root.dismissed();
                }
            }
        }
    }

    // Host writes these two; kept off `menu` directly so the clamp math above
    // has stable inputs.
    property real _px: 0
    property real _py: 0
}
