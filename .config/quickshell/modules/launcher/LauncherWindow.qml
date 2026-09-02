import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.widgets

// The launcher surface for one output: a search card that drops in under the
// bar, over a scrim that dismisses it.
//
// Always mapped, never toggling `visible` — the same safety pattern the bar
// editor's overlay uses, since an imperatively shown layer-shell surface never
// survives a hot reload. What actually opens and closes is the input mask (so
// a closed launcher is click-through) and the keyboard grab.
PanelWindow {
    id: win

    readonly property bool open: LauncherController.openOn === (screen?.name ?? "")

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:launcher"
    // Exclusive, unlike every other surface in this shell: the launcher is a
    // text field, and it has to be typed into the moment it appears rather
    // than after a click.
    WlrLayershell.keyboardFocus: open
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // 0, not -1: the card hangs off the bar's exclusive zone, so it starts
    // measuring from just below the bar the way the dashboard does.
    exclusiveZone: 0
    color: "transparent"
    visible: true

    anchors { top: true; left: true; right: true; bottom: true }

    // Closed, the whole surface is a hole — clicks land on whatever is behind
    // it. The card's exit animation still plays; this is the input region, not
    // what's drawn.
    mask: Region {
        width: win.open ? win.width : 0
        height: win.open ? win.height : 0
    }

    onOpenChanged: if (open) search.takeFocus()

    // Click anywhere off the card to dismiss. niri has no equivalent of
    // Hyprland's focus grab, so this MouseArea over the whole output is what a
    // click outside actually hits.
    MouseArea {
        anchors.fill: parent
        onClicked: LauncherController.hide()
    }

    Rectangle {
        id: card

        x: Math.round((parent.width - width) / 2)
        // Closed, it sits a short hop above where it lands rather than all the
        // way off the top of the screen: a long slide reads as slow however
        // quick the animation is set to.
        y: win.open ? Theme.launcher.topMargin
                    : Theme.launcher.topMargin - Theme.spacing.large
        width: Math.min(Theme.launcher.width,
                        parent.width - Theme.frame.thickness * 2 - Theme.popup.margin * 2)
        implicitHeight: col.implicitHeight + Theme.launcher.padding * 2
        height: implicitHeight

        color: Theme.popup.background
        radius: Theme.popup.radius
        border.color: Theme.popup.border
        border.width: Theme.popup.borderWidth
        opacity: win.open ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: Theme.animation.instant
                easing.type: Easing.OutCubic
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Theme.animation.instant
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.animation.instant }
        }

        // Swallows clicks so they don't fall through to the scrim behind.
        MouseArea {
            anchors.fill: parent
        }

        SoftShadow {}

        ColumnLayout {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.launcher.padding
            spacing: Theme.spacing.small

            SearchField {
                id: search
                Layout.fillWidth: true
                onAccepted: LauncherController.activate()
                onDismissed: {
                    if (ctxMenu.open)
                        ctxMenu.open = false;
                    else
                        LauncherController.hide();
                }
            }

            // --- results ------------------------------------------------------
            ListView {
                id: list

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, Theme.launcher.maxListHeight)
                visible: count > 0
                clip: true
                model: LauncherController.results
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                // The search field owns the keyboard; this is a list you steer
                // from there, so it must never take focus of its own.
                interactive: contentHeight > height
                currentIndex: LauncherController.selected
                highlightMoveDuration: 0
                // Keeps the selection on screen when it walks off either end,
                // including the wrap from the last row back to the first.
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: ResultRow {
                    required property var modelData
                    required property int index

                    width: list.width
                    result: modelData
                    selected: index === LauncherController.selected
                    onActivated: LauncherController.activate(index)
                    onContextRequested: pos => {
                        ctxMenu.appId = modelData.appId ?? "";
                        ctxMenu._px = pos.x;
                        ctxMenu._py = pos.y;
                        ctxMenu.open = ctxMenu.appId.length > 0;
                    }
                }
            }

            // Nothing matched. Says so rather than collapsing to a bare search
            // box, which reads as the launcher having stopped working.
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.launcher.rowHeight
                visible: LauncherController.count === 0
                    && LauncherController.query.length > 0

                Text {
                    anchors.centerIn: parent
                    text: LauncherController.mode
                        ? ("Nothing to " + LauncherController.mode.verb.toLowerCase() + " yet")
                        : "No matches"
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.medium
                    color: Theme.colors.textTertiary
                }
            }

            // --- mode hints ---------------------------------------------------
            // The prefixes are the launcher's only hidden feature, so they are
            // spelled out along the bottom — and each one is a button, for the
            // times it's easier to click than to remember which character it
            // was.
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.spacing.tiny
                Layout.topMargin: Theme.spacing.tiny
                spacing: Theme.spacing.small

                Repeater {
                    model: LauncherConfig.modes

                    delegate: Rectangle {
                        id: chip
                        required property var modelData
                        readonly property bool on:
                            LauncherController.mode?.id === modelData.id

                        implicitWidth: chipRow.implicitWidth + Theme.spacing.normal * 2
                        implicitHeight: 24
                        radius: height / 2
                        color: on ? Theme.colors.accent
                            : (chipMouse.containsMouse ? Theme.colors.surfaceVariant
                               : "transparent")

                        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: Theme.spacing.tiny

                            Text {
                                text: chip.modelData.prefix
                                font.family: Theme.font.mono
                                font.pointSize: Theme.font.small
                                font.weight: Theme.font.semiBold
                                color: chip.on ? Theme.colors.bg : Theme.colors.accent
                            }

                            Text {
                                text: chip.modelData.name
                                font.family: Theme.font.main
                                font.pointSize: Theme.font.small
                                color: chip.on ? Theme.colors.bg : Theme.colors.textTertiary
                            }
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            // Clicking the active chip drops back to searching
                            // apps, so the row toggles rather than latching.
                            onClicked: {
                                LauncherController.setMode(chip.on ? "" : chip.modelData.id);
                                search.takeFocus();
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    // Right-click menu for an app row (pin / hide). Fills the window so it can
    // be positioned in window coords and dismissed by an outside click.
    LauncherContextMenu {
        id: ctxMenu
        onDismissed: {
            open = false;
            search.takeFocus();
        }
    }
}
