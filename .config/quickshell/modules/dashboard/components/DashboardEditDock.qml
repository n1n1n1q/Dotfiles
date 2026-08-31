import QtQuick
import QtQuick.Layouts
import qs.config

// The pool + actions dock, shown at the bottom of the dashboard while
// DashboardConfig.editMode is on. Everything not currently in the panel sits
// here as a draggable tile; dropping a placed tile back on the dock removes it.
Rectangle {
    id: dock

    property var ghost: null

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + Theme.spacing.normal * 2
    radius: Theme.rounding.medium
    color: Theme.colors.surface0

    DropArea {
        id: removeZone
        anchors.fill: parent
        // A fresh tile dropped back here just never lands; a placed one leaves.
        enabled: DashboardConfig.grabbing
        onDropped: drop => {
            DashboardConfig.dropRemove();
            drop.accept();
        }

        Rectangle {
            anchors.fill: parent
            radius: dock.radius
            visible: removeZone.containsDrag
            color: Qt.rgba(Theme.colors.error.r, Theme.colors.error.g, Theme.colors.error.b, 0.14)
            border.width: 1
            border.color: Theme.colors.error
        }
    }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top
                  margins: Theme.spacing.normal }
        spacing: Theme.spacing.small

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: DashboardConfig.grabbing
                ? "Drop on a marker to place · drop here to remove · Esc to cancel"
                : "Drag a tile in · click a placed one to resize or restyle it"
            font.family: Theme.font.main
            font.pointSize: Theme.font.tiny
            color: Theme.colors.textSecondary
        }

        PoolFlow {
            kind: "toggles"
            entries: DashboardConfig.availableToggles
            emptyText: "Every quick setting is placed"
        }

        PoolFlow {
            kind: "sliders"
            entries: DashboardConfig.availableSliders
            emptyText: "Every slider is placed"
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spacing.small

            DockBtn { label: "Reset";  onActivated: DashboardConfig.reset() }
            DockBtn { label: "Cancel"; onActivated: DashboardConfig.cancelEdit() }
            DockBtn { label: "Done"; accent: true; onActivated: DashboardConfig.commitEdit() }
        }
    }

    // ---------------------------------------------------------------------
    component DockBtn: Rectangle {
        id: db
        property string label: ""
        property bool accent: false
        signal activated()

        implicitWidth: dbT.implicitWidth + Theme.spacing.normal * 2
        implicitHeight: 26
        radius: Theme.rounding.small
        color: db.accent
            ? (dbM.containsMouse ? Theme.colors.accentAlt : Theme.colors.accent)
            : (dbM.containsMouse ? Theme.colors.surfaceVariant : Theme.colors.surface)
        border.width: db.accent ? 0 : 1
        border.color: Theme.colors.border

        Text {
            id: dbT
            anchors.centerIn: parent
            text: db.label
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            font.weight: Theme.font.semiBold
            color: db.accent ? Theme.colors.bg : Theme.colors.textPrimary
        }

        MouseArea {
            id: dbM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: db.activated()
        }
    }

    component PoolFlow: ColumnLayout {
        id: pool
        property string kind: "toggles"
        property var entries: []
        property string emptyText: ""

        Layout.fillWidth: true
        spacing: Theme.spacing.tiny

        Text {
            visible: pool.entries.length === 0
            text: pool.emptyText
            font.family: Theme.font.main
            font.pointSize: Theme.font.tiny
            color: Theme.colors.textTertiary
        }

        Flow {
            Layout.fillWidth: true
            spacing: Theme.spacing.tiny

            Repeater {
                model: pool.entries

                delegate: Item {
                    id: poolTile
                    required property var modelData

                    readonly property bool picked: DashboardConfig.grabbing
                        && DashboardConfig.grab.mode === "new"
                        && DashboardConfig.grab.kind === pool.kind
                        && DashboardConfig.grab.id === modelData.id

                    implicitWidth: ptRow.implicitWidth + Theme.spacing.normal * 2
                    implicitHeight: 30

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.rounding.small
                        color: poolTile.picked ? Theme.colors.accent
                            : (ptM.containsMouse ? Theme.colors.surfaceVariant : Theme.colors.surface)
                        border.width: 1
                        border.color: poolTile.picked ? Theme.colors.accent : Theme.colors.border
                    }

                    Row {
                        id: ptRow
                        anchors.centerIn: parent
                        spacing: Theme.spacing.tiny

                        Text {
                            text: poolTile.modelData.icon ?? "󰋙"
                            font.family: Theme.font.icon
                            font.pointSize: Theme.font.medium
                            color: poolTile.picked ? Theme.colors.bg : Theme.colors.accent
                        }
                        Text {
                            text: poolTile.modelData.name ?? ""
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.small
                            color: poolTile.picked ? Theme.colors.bg : Theme.colors.textPrimary
                        }
                    }

                    MouseArea {
                        id: ptM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.OpenHandCursor
                        // Keep the enclosing ScrollView from stealing the drag.
                        preventStealing: true

                        property bool dragging: false
                        property point origin: Qt.point(0, 0)

                        function abort() {
                            if (!ptM.dragging) return;
                            ptM.dragging = false;
                            dock.ghost?.finish();
                        }

                        onPressed: mouse => {
                            dragging = false;
                            origin = Qt.point(mouse.x, mouse.y);
                        }
                        onPositionChanged: mouse => {
                            if (ptM.dragging) {
                                dock.ghost?.moveTo(ptM, mouse.x, mouse.y);
                                return;
                            }
                            // Hover moves land here too, so a drag needs both a
                            // held button and the platform drag threshold.
                            if (!ptM.pressed)
                                return;
                            const dx = mouse.x - ptM.origin.x;
                            const dy = mouse.y - ptM.origin.y;
                            if (Math.abs(dx) + Math.abs(dy) < Qt.styleHints.startDragDistance)
                                return;
                            ptM.dragging = true;
                            DashboardConfig.pickNew(pool.kind, poolTile.modelData.id);
                            dock.ghost?.begin(ptM, mouse.x, mouse.y);
                        }
                        onReleased: {
                            if (ptM.dragging)
                                ptM.abort();
                            else
                                // A plain click just appends it.
                                DashboardConfig.add(pool.kind, poolTile.modelData.id);
                        }
                        onCanceled: ptM.abort()
                    }
                }
            }
        }
    }
}
