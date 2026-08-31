import QtQuick
import QtQuick.Layouts
import qs.config

// The quick-settings grid: DashboardConfig.columns cells wide, as many rows as
// the configured toggles need. A "small" tile takes one cell and shows only its
// glyph; a "large" one spans two and adds a name / status line.
//
// In edit mode every tile jiggles: hold one and drag it onto the accent bar
// that lights up at a cell edge to reorder, drop it on the dock to remove it,
// or just click it to flip between one and two cells wide.
ColumnLayout {
    id: root

    // The window-level DragProxy, so the ghost can float over the ScrollView.
    property var ghost: null
    // Raised when a one-shot tile (screenshot, lock, ...) wants the panel gone.
    signal closeRequested()

    readonly property bool editing: DashboardConfig.editMode
    readonly property int count: DashboardConfig.toggles.length

    Layout.fillWidth: true
    spacing: Theme.spacing.small

    Text {
        visible: root.editing
        text: "Quick settings — drag to reorder, click to resize"
        font.family: Theme.font.main
        font.pointSize: Theme.font.tiny
        color: Theme.colors.textTertiary
    }

    GridLayout {
        id: grid

        Layout.fillWidth: true
        columns: DashboardConfig.columns
        columnSpacing: Theme.spacing.small
        rowSpacing: Theme.spacing.small

        Repeater {
            model: DashboardConfig.toggles

            delegate: Item {
                id: cell

                required property var modelData
                required property int index
                readonly property string tid: modelData.id
                readonly property string tsize: modelData.size ?? "small"
                readonly property bool held: DashboardConfig.grabbing
                    && DashboardConfig.grab.kind === "toggles"
                    && DashboardConfig.grab.mode === "move"
                    && DashboardConfig.grab.index === index

                Layout.columnSpan: tsize === "large" ? 2 : 1
                Layout.fillWidth: true
                Layout.preferredHeight: 56

                opacity: held ? 0.25 : 1

                transformOrigin: Item.Center
                SequentialAnimation on rotation {
                    running: root.editing && !cell.held
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.2; duration: 130; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -1.2; duration: 130; easing.type: Easing.InOutSine }
                }
                onHeldChanged: if (held) rotation = 0

                QuickToggle {
                    id: toggle
                    anchors.fill: parent
                    toggleId: cell.tid
                    size: cell.tsize
                    editing: root.editing
                    onActivated: {
                        // `run()` reports whether the panel should stay put:
                        // flipping a radio does, launching something doesn't.
                        if (!run())
                            root.closeRequested();
                    }
                }

                // --- edit chrome -------------------------------------------
                Rectangle {
                    anchors.fill: parent
                    visible: root.editing
                    radius: Theme.rounding.medium
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g,
                                          Theme.colors.accent.b, 0.5)
                }

                // `hoverEnabled` stays off on purpose: onPositionChanged then
                // only fires while a button is actually down, so a pointer
                // drifting across the panel can't start a drag on its own.
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    enabled: root.editing
                    cursorShape: Qt.OpenHandCursor
                    // The panel scrolls; without this the ScrollView's
                    // Flickable steals a vertical drag and the tile never
                    // leaves its cell.
                    preventStealing: true

                    property bool dragging: false
                    property point origin: Qt.point(0, 0)

                    function abort() {
                        if (!dragArea.dragging) return;
                        dragArea.dragging = false;
                        root.ghost?.finish();
                    }

                    onPressed: mouse => {
                        dragging = false;
                        origin = Qt.point(mouse.x, mouse.y);
                    }
                    onPositionChanged: mouse => {
                        if (dragArea.dragging) {
                            root.ghost?.moveTo(dragArea, mouse.x, mouse.y);
                            return;
                        }
                        // Only past the platform drag threshold, so a click
                        // that wobbles a pixel still counts as a click.
                        const dx = mouse.x - dragArea.origin.x;
                        const dy = mouse.y - dragArea.origin.y;
                        if (Math.abs(dx) + Math.abs(dy) < Qt.styleHints.startDragDistance)
                            return;
                        dragArea.dragging = true;
                        DashboardConfig.pickPlaced("toggles", cell.index);
                        root.ghost?.begin(dragArea, mouse.x, mouse.y);
                    }
                    onReleased: {
                        if (dragArea.dragging) {
                            dragArea.abort();
                        } else {
                            // A plain click in edit mode resizes the tile.
                            DashboardConfig.cycleToggleSize(cell.index);
                        }
                    }
                    // The compositor took the grab away mid-drag - don't leave
                    // the tile stuck to the cursor.
                    onCanceled: dragArea.abort()
                }

                // Insert markers: the left half of a tile drops before it, the
                // right half after.
                Row {
                    anchors.fill: parent
                    visible: root.editing
                    DropSlot {
                        width: parent.width / 2
                        height: parent.height
                        kind: "toggles"
                        index: cell.index
                        edge: "left"
                    }
                    DropSlot {
                        width: parent.width / 2
                        height: parent.height
                        kind: "toggles"
                        index: cell.index + 1
                        edge: "right"
                    }
                }

                // Remove, hanging off the top-left corner like the notification
                // close button.
                Rectangle {
                    visible: root.editing && !DashboardConfig.grabbing
                    width: 18
                    height: 18
                    radius: 9
                    color: rmMouse.containsMouse ? Theme.colors.error : Theme.colors.surfaceVariant
                    border.width: 1
                    border.color: Theme.colors.error
                    anchors.horizontalCenter: parent.left
                    anchors.verticalCenter: parent.top
                    anchors.horizontalCenterOffset: 3
                    anchors.verticalCenterOffset: 3
                    z: 2

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Theme.font.icon
                        font.pointSize: Theme.font.tiny
                        color: rmMouse.containsMouse ? Theme.colors.bg : Theme.colors.error
                    }

                    MouseArea {
                        id: rmMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DashboardConfig.removeAt("toggles", cell.index)
                    }
                }
            }
        }

        // Append target — also the only drop point when the grid is empty.
        Item {
            Layout.columnSpan: 1
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            visible: root.editing

            Rectangle {
                anchors.fill: parent
                radius: Theme.rounding.medium
                color: appendSlot.containsDrag || picker.open
                    ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.16)
                    : (addMouse.containsMouse ? Theme.colors.surface : "transparent")
                border.width: 1
                border.color: appendSlot.containsDrag || picker.open
                    ? Theme.colors.accent : Theme.colors.border

                Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                Text {
                    anchors.centerIn: parent
                    text: picker.open ? "󰅖" : "󰐕"
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.medium
                    color: picker.open || addMouse.containsMouse
                        ? Theme.colors.accent : Theme.colors.textTertiary
                }
            }

            // Clicking it opens the list of unplaced tiles; dragging onto it
            // appends whatever is being held.
            MouseArea {
                id: addMouse
                anchors.fill: parent
                enabled: !DashboardConfig.grabbing
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: picker.open = !picker.open
            }

            DropSlot {
                id: appendSlot
                anchors.fill: parent
                kind: "toggles"
                index: root.count
                edge: "left"
            }
        }
    }

    AddPicker {
        id: picker
        kind: "toggles"
        entries: DashboardConfig.availableToggles
        onPicked: entryId => {
            DashboardConfig.add("toggles", entryId);
            if (DashboardConfig.availableToggles.length === 0)
                open = false;
        }
    }

    // Leaving edit mode with the list still hanging open would strand it.
    Connections {
        target: DashboardConfig
        function onEditModeChanged() { if (!DashboardConfig.editMode) picker.open = false }
    }

    Text {
        visible: root.count === 0 && !root.editing
        Layout.fillWidth: true
        text: "No quick settings — add some in Settings › Dashboard"
        wrapMode: Text.WordWrap
        font.family: Theme.font.main
        font.pointSize: Theme.font.small
        color: Theme.colors.textTertiary
    }
}
