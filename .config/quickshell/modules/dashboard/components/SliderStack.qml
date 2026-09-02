import QtQuick
import QtQuick.Layouts
import qs.config

// The configured slider rows, in one surface card. Same editing model as the
// quick-settings grid: hold a row and drag it to reorder, drop it on the dock
// to remove it, click it to step through the styles in
// DashboardConfig.sliderStyles.
ColumnLayout {
    id: root

    property var ghost: null

    readonly property bool editing: DashboardConfig.editMode
    readonly property int count: DashboardConfig.sliders.length

    Layout.fillWidth: true
    spacing: Theme.spacing.small

    Text {
        visible: root.editing
        text: "Sliders — drag to reorder, click to change style"
        font.family: Theme.font.main
        font.pointSize: Theme.dashboard.fontTiny
        color: Theme.colors.textTertiary
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: col.implicitHeight + Theme.padding.normal * 2
        visible: root.count > 0 || root.editing
        radius: Theme.rounding.huge
        color: Theme.colors.surface

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top
                      margins: Theme.padding.normal }
            spacing: Theme.spacing.small

            Repeater {
                model: DashboardConfig.sliders

                delegate: Item {
                    id: rowItem

                    required property var modelData
                    required property int index
                    readonly property bool held: DashboardConfig.grabbing
                        && DashboardConfig.grab.kind === "sliders"
                        && DashboardConfig.grab.mode === "move"
                        && DashboardConfig.grab.index === index

                    Layout.fillWidth: true
                    implicitHeight: body.implicitHeight
                    opacity: held ? 0.25 : 1

                    transformOrigin: Item.Center
                    SequentialAnimation on rotation {
                        running: root.editing && !rowItem.held
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.4; duration: 150; easing.type: Easing.InOutSine }
                        NumberAnimation { to: -0.4; duration: 150; easing.type: Easing.InOutSine }
                    }
                    onHeldChanged: if (held) rotation = 0

                    ColumnLayout {
                        id: body
                        width: parent.width
                        spacing: 0

                        DashSlider {
                            Layout.fillWidth: true
                            sliderId: rowItem.modelData.id
                            // One global style now — Settings › Appearance.
                            style: Appearance.sliderStyle
                            editing: root.editing
                        }
                    }

                    // --- edit chrome ---------------------------------------
                    Rectangle {
                        anchors.fill: parent
                        visible: root.editing
                        radius: Theme.rounding.small
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g,
                                              Theme.colors.accent.b, 0.5)
                    }

                    // No hover: onPositionChanged then only fires while a
                    // button is down, so the pointer can't start a drag by
                    // merely crossing the row.
                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        enabled: root.editing
                        cursorShape: Qt.OpenHandCursor
                        // Keep the enclosing ScrollView from stealing the drag.
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
                            const dx = mouse.x - dragArea.origin.x;
                            const dy = mouse.y - dragArea.origin.y;
                            if (Math.abs(dx) + Math.abs(dy) < Qt.styleHints.startDragDistance)
                                return;
                            dragArea.dragging = true;
                            DashboardConfig.pickPlaced("sliders", rowItem.index);
                            root.ghost?.begin(dragArea, mouse.x, mouse.y);
                        }
                        onReleased: {
                            if (dragArea.dragging)
                                dragArea.abort();
                        }
                        onCanceled: dragArea.abort()
                    }

                    Column {
                        anchors.fill: parent
                        visible: root.editing
                        DropSlot {
                            width: parent.width
                            height: parent.height / 2
                            kind: "sliders"
                            index: rowItem.index
                            edge: "top"
                        }
                        DropSlot {
                            width: parent.width
                            height: parent.height / 2
                            kind: "sliders"
                            index: rowItem.index + 1
                            edge: "bottom"
                        }
                    }

                    // Remove button, only while editing.
                    Row {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 2
                        spacing: Theme.spacing.tiny
                        visible: root.editing && !DashboardConfig.grabbing
                        z: 2

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: rmMouse.containsMouse ? Theme.colors.error : Theme.colors.surfaceVariant
                            border.width: 1
                            border.color: Theme.colors.error

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: Theme.font.icon
                                font.pointSize: Theme.dashboard.fontTiny
                                color: rmMouse.containsMouse ? Theme.colors.bg : Theme.colors.error
                            }

                            MouseArea {
                                id: rmMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: DashboardConfig.removeAt("sliders", rowItem.index)
                            }
                        }
                    }
                }
            }

            // Append target while editing.
            Item {
                Layout.fillWidth: true
                implicitHeight: 30
                visible: root.editing

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.rounding.small
                    color: appendSlot.containsDrag || picker.open
                        ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.16)
                        : (addMouse.containsMouse ? Theme.colors.surface : "transparent")
                    border.width: 1
                    border.color: appendSlot.containsDrag || picker.open
                        ? Theme.colors.accent : Theme.colors.border

                    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                    Text {
                        anchors.centerIn: parent
                        text: root.count === 0 ? "Add a slider" : (picker.open ? "󰅖" : "󰐕")
                        font.family: root.count === 0 ? Theme.font.main : Theme.font.icon
                        font.pointSize: Theme.dashboard.fontSmall
                        color: picker.open || addMouse.containsMouse
                            ? Theme.colors.accent : Theme.colors.textTertiary
                    }
                }

                // Click to pick from the unplaced sliders; drop to append.
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
                    kind: "sliders"
                    index: root.count
                    edge: "top"
                }
            }
        }
    }

    AddPicker {
        id: picker
        kind: "sliders"
        entries: DashboardConfig.availableSliders
        onPicked: entryId => {
            DashboardConfig.add("sliders", entryId);
            if (DashboardConfig.availableSliders.length === 0)
                open = false;
        }
    }

    Connections {
        target: DashboardConfig
        function onEditModeChanged() { if (!DashboardConfig.editMode) picker.open = false }
    }
}
