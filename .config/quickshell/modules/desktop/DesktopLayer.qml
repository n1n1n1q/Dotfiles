import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services.niri

// The desktop-widget surface: one always-mapped layer-shell window per screen.
// Sits on the Bottom layer (above the wallpaper, below windows) at rest and is
// click-through; in edit mode (or while placing a new widget) it rises to the
// Top layer, takes keyboard focus (Shift = snap, Enter = save, Esc = cancel)
// and becomes interactive.
Scope {
    id: scope

    // Cancel an in-progress edit when the focused workspace changes.
    readonly property int focusedWsIdx: NiriService.focusedWorkspace?.idx ?? -1
    onFocusedWsIdxChanged: if (DesktopConfig.editMode) DesktopConfig.cancelEdit()

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData

            property var guides: []
            property bool shiftHeld: false
            readonly property bool grabbing: DesktopConfig.grabbedId !== ""
            readonly property bool interactive: DesktopConfig.editMode || grabbing
            // is the widget being placed assigned to *this* output?
            readonly property bool grabbingHere: {
                if (!grabbing) return false;
                const w = DesktopConfig.widgets.find(x => x.id === DesktopConfig.grabbedId);
                return w && w.screen === win.modelData.name;
            }

            WlrLayershell.layer: interactive ? WlrLayer.Top : WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:desktop"
            WlrLayershell.keyboardFocus: interactive
                ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            exclusiveZone: 0
            color: "transparent"
            visible: true

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            mask: Region {
                width: win.interactive ? win.width : 0
                height: win.interactive ? win.height : 0
            }

            function otherRects(excludeId) {
                let out = [];
                for (let i = 0; i < rep.count; i++) {
                    const it = rep.itemAt(i);
                    if (it && it.model && it.model.id !== excludeId && it.width > 0)
                        out.push({ x: it.localX, y: it.localY, w: it.width, h: it.height });
                }
                return out;
            }
            function grabbedItem() {
                for (let i = 0; i < rep.count; i++) {
                    const it = rep.itemAt(i);
                    if (it && it.model && it.model.id === DesktopConfig.grabbedId)
                        return it;
                }
                return null;
            }

            // key catcher
            Item {
                anchors.fill: parent
                focus: win.interactive
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Shift) {
                        win.shiftHeld = true;
                    } else if (e.key === Qt.Key_Escape) {
                        if (win.grabbing) DesktopConfig.placeCancel();
                        else DesktopConfig.cancelEdit();
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        if (!win.grabbing) DesktopConfig.commitEdit();
                        e.accepted = true;
                    }
                }
                Keys.onReleased: e => {
                    if (e.key === Qt.Key_Shift)
                        win.shiftHeld = false;
                }
            }

            Item {
                id: contentArea
                anchors.fill: parent

                // click empty space to deselect
                MouseArea {
                    anchors.fill: parent
                    enabled: DesktopConfig.editMode && !win.grabbing
                    onClicked: DesktopConfig.selectedId = ""
                }

                Repeater {
                    id: rep
                    model: DesktopConfig.widgets.filter(w =>
                        w.screen === win.modelData.name || w.screen === "all")
                    delegate: DesktopWidget {
                        required property var modelData
                        model: modelData
                        screenName: win.modelData.name
                        area: contentArea
                        shiftHeld: win.shiftHeld
                        opacity: modelData.id === DesktopConfig.grabbedId ? 0.6 : 1
                        publishGuides: gs => win.guides = gs
                        otherRects: () => win.otherRects(modelData.id)
                    }
                }

                // While placing a new widget, it follows the pointer; a click
                // drops it.
                MouseArea {
                    anchors.fill: parent
                    enabled: win.grabbingHere
                    hoverEnabled: true
                    cursorShape: Qt.CrossCursor
                    onPositionChanged: mouse => {
                        const it = win.grabbedItem();
                        if (!it) return;
                        it.localX = Math.max(0, Math.min(mouse.x - it.width / 2, win.width - it.width));
                        it.localY = Math.max(0, Math.min(mouse.y - it.height / 2, win.height - it.height));
                    }
                    onClicked: {
                        const it = win.grabbedItem();
                        DesktopConfig.placeCommit(it ? it.localX : 120, it ? it.localY : 120);
                    }
                }
            }

            // alignment guides
            Repeater {
                model: win.guides
                delegate: Rectangle {
                    required property var modelData
                    color: Theme.colors.accent
                    opacity: 0.85
                    x: modelData.o === "v" ? modelData.p : 0
                    y: modelData.o === "h" ? modelData.p : 0
                    width: modelData.o === "v" ? 1 : win.width
                    height: modelData.o === "h" ? 1 : win.height
                }
            }

            // top-centre hint pill
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Theme.bar.height + Theme.popup.margin
                visible: DesktopConfig.editMode || win.grabbing
                implicitWidth: hintRow.implicitWidth + Theme.spacing.large * 2
                implicitHeight: hintRow.implicitHeight + Theme.spacing.normal * 2
                radius: Theme.popup.radius
                color: Theme.popup.background
                border.width: Theme.popup.borderWidth
                border.color: Theme.popup.border

                RowLayout {
                    id: hintRow
                    anchors.centerIn: parent
                    spacing: Theme.spacing.medium

                    Text {
                        text: win.grabbing
                            ? "Move the mouse, then click to drop the widget · Esc cancels"
                            : "Click a widget to select · drag to move · corner to resize · Shift to snap · Enter save · Esc cancel"
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.small
                        color: Theme.colors.textSecondary
                    }
                    Rectangle {
                        visible: !win.grabbing
                        implicitWidth: doneText.implicitWidth + Theme.spacing.normal * 2
                        implicitHeight: 26
                        radius: Theme.rounding.small
                        color: doneMouse.containsMouse ? Theme.colors.accent : Theme.colors.surfaceVariant
                        Text {
                            id: doneText
                            anchors.centerIn: parent
                            text: "Done"
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.small
                            font.weight: Theme.font.semiBold
                            color: doneMouse.containsMouse ? Theme.colors.bg : Theme.colors.textPrimary
                        }
                        MouseArea {
                            id: doneMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DesktopConfig.commitEdit()
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: DesktopConfig.editMode && !win.grabbing && rep.count === 0
                text: "No widgets on this screen.\nAdd one from Settings › Widgets."
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.font.main
                font.pointSize: Theme.font.medium
                color: Theme.colors.textTertiary
            }
        }
    }
}
