import QtQuick
import qs.config

// The whole bar-layout editor UI, living in one Item so plain QtQuick
// drag-and-drop works end to end. Embedded by BarEditOverlay into a
// full-screen, click-through overlay window per screen.
//
// Interaction: hold a widget (on the bar replica) or a pool tile, a ghost
// follows the cursor across the entire screen, drop it on an insert marker.
// Release anywhere else and the ghost just vanishes — nothing changes. Drop a
// bar widget back onto the dock to remove it. Enter saves, Esc cancels.
Item {
    id: stage

    property bool active: false
    property var panelWindow: null
    property string screenName: ""

    readonly property var grab: BarConfig.grab
    readonly property bool grabbing: grab !== null
    readonly property real barH: Theme.workspace.indicatorHeight

    opacity: active ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }

    function grabLabel() {
        const g = BarConfig.grab;
        if (!g) return "";
        if (g.kind === "group") return "Group";
        return BarConfig.widgetName(g.widgetId);
    }
    function grabGlyph() {
        const g = BarConfig.grab;
        if (!g) return "";
        if (g.kind === "group") return "󰏬";
        return BarConfig.widgetIcon(g.widgetId);
    }

    // faint dim — modal, but the desktop still shows through so a dragged
    // widget reads as floating "over" everything
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
        MouseArea {
            anchors.fill: parent
            // a plain click on empty space finishes editing
            onClicked: BarConfig.commitEdit()
        }
    }

    // Enter saves, Esc drops a grab then ends the session
    Item {
        anchors.fill: parent
        focus: stage.active
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) {
                if (BarConfig.grab) BarConfig.cancelGrab();
                else BarConfig.commitEdit();
                e.accepted = true;
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                BarConfig.commitEdit();
                e.accepted = true;
            }
        }
    }

    // ---- the editable bar strip (replica, covers the real bar) -----------
    Rectangle {
        id: strip
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Theme.bar.height
        color: Theme.bar.background

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Theme.frame.thickness
            color: Theme.frame.color
        }

        Region {
            section: "left"
            groups: BarConfig.left
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacing.medium
            anchors.verticalCenter: parent.verticalCenter
        }
        Region {
            section: "center"
            groups: BarConfig.center
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }
        Region {
            section: "right"
            groups: BarConfig.right
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacing.medium + Theme.spacing.normal
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ---- the pool / actions dock ----------------------------------------
    Rectangle {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: strip.bottom
        anchors.topMargin: Theme.popup.margin + 10
        width: Math.min(parent.width - 80, 760)
        implicitHeight: dockCol.implicitHeight + Theme.spacing.large * 2
        radius: Theme.popup.radius
        color: Theme.popup.background

        // drop a bar widget (or group) here to remove it
        DropArea {
            id: removeZone
            anchors.fill: parent
            onDropped: drop => {
                BarConfig.placeGrab("remove", "", 0, 0);
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

        Column {
            id: dockCol
            anchors.centerIn: parent
            width: parent.width - Theme.spacing.large * 2
            spacing: Theme.spacing.normal

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: stage.grabbing
                    ? "Drop on a marker to place · drop here to remove · Esc to cancel"
                    : "Hold a widget and drag it onto the bar · Enter saves · Esc cancels"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textSecondary
            }

            Flow {
                width: parent.width
                spacing: Theme.spacing.small
                Repeater {
                    model: BarConfig.catalogue
                    delegate: PoolTile {
                        required property var modelData
                        entry: modelData
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacing.small
                DockBtn { label: "Reset";  onClicked: BarConfig.reset() }
                DockBtn { label: "Cancel"; onClicked: BarConfig.cancelEdit() }
                DockBtn { label: "Done"; accent: true; onClicked: BarConfig.commitEdit() }
            }
        }
    }

    // ---- the drag ghost, above everything -------------------------------
    Item {
        id: proxy
        z: 10000
        width: ghostRow.implicitWidth + Theme.spacing.normal * 2
        height: 28
        visible: false
        Drag.active: visible
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        function begin(pt) { moveTo(pt); visible = true; }
        function moveTo(pt) { x = pt.x - width / 2; y = pt.y - height / 2; }
        function finish() {
            if (!visible) return;
            Drag.drop();
            visible = false;
            if (BarConfig.grab)   // nothing caught it
                BarConfig.cancelGrab();
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.rounding.small
            color: Theme.colors.accent
            opacity: 0.93
            Row {
                id: ghostRow
                anchors.centerIn: parent
                spacing: Theme.spacing.tiny
                Text {
                    text: stage.grabGlyph()
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.small
                    color: Theme.colors.bg
                }
                Text {
                    text: stage.grabLabel()
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.small
                    font.weight: Theme.font.semiBold
                    color: Theme.colors.bg
                }
            }
        }
    }

    // ====================== inline components ============================
    component DockBtn: Rectangle {
        id: db
        property string label: ""
        property bool accent: false
        signal clicked()
        implicitWidth: dbT.implicitWidth + Theme.spacing.normal * 2
        implicitHeight: 28
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
            onClicked: db.clicked()
        }
    }

    component PoolTile: Item {
        id: pooltile
        property var entry: ({})
        implicitWidth: ptRow.implicitWidth + Theme.spacing.normal * 2
        implicitHeight: 34

        readonly property bool picked: stage.grabbing
            && BarConfig.grab.kind === "new"
            && BarConfig.grab.widgetId === entry.id

        Rectangle {
            anchors.fill: parent
            radius: Theme.rounding.small
            color: pooltile.picked ? Theme.colors.accent
                : (ptM.containsMouse ? Theme.colors.surfaceVariant : Theme.colors.surface)
            border.width: 1
            border.color: pooltile.picked ? Theme.colors.accent : Theme.colors.border
        }
        Row {
            id: ptRow
            anchors.centerIn: parent
            spacing: Theme.spacing.tiny
            Text {
                text: pooltile.entry.icon ?? "󰋙"
                font.family: Theme.font.icon
                font.pointSize: Theme.font.medium
                color: pooltile.picked ? Theme.colors.bg : Theme.colors.accent
            }
            Text {
                text: pooltile.entry.name ?? ""
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: pooltile.picked ? Theme.colors.bg : Theme.colors.textPrimary
            }
        }
        MouseArea {
            id: ptM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.OpenHandCursor
            property bool active: false
            onPressed: active = false
            onPositionChanged: mouse => {
                const pt = mapToItem(stage, mouse.x, mouse.y);
                if (!ptM.active && ptM.pressed) {
                    ptM.active = true;
                    BarConfig.pickNewWidget(pooltile.entry.id);
                    proxy.begin(pt);
                } else if (ptM.active) {
                    proxy.moveTo(pt);
                }
            }
            onReleased: {
                if (ptM.active) {
                    ptM.active = false;
                    proxy.finish();
                }
            }
        }
    }

    component Marker: DropArea {
        id: mk
        property string section: ""
        property string kind: ""        // "widget-gap" | "new-group"
        property int a: 0
        property int b: 0
        property bool wide: false

        // a group only drops between groups
        readonly property bool usable: stage.grabbing
            && (stage.grab.kind !== "group" || kind === "new-group")

        visible: usable
        implicitWidth: usable ? (containsDrag ? 24 : (wide ? 16 : 10)) : 0
        implicitHeight: stage.barH
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        Behavior on implicitWidth { NumberAnimation { duration: Theme.animation.fast } }

        Rectangle {
            anchors.centerIn: parent
            width: mk.containsDrag ? 6 : (mk.wide ? 4 : 2)
            height: parent.height * (mk.wide ? 0.92 : 0.6)
            radius: width / 2
            color: mk.containsDrag ? Theme.colors.accent : Theme.colors.accentAlt
            opacity: mk.containsDrag ? 1 : 0.5
            Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }
        }
        onDropped: drop => {
            BarConfig.placeGrab(mk.kind, mk.section, mk.a, mk.b);
            drop.accept();
        }
    }

    component WidgetTile: Item {
        id: tile
        property string section: ""
        property int groupIndex: 0
        property int widgetIndex: 0
        property string widgetId: ""

        readonly property bool isGrabbed: stage.grabbing
            && stage.grab.kind === "move"
            && stage.grab.section === section
            && stage.grab.groupIndex === groupIndex
            && stage.grab.widgetIndex === widgetIndex

        implicitWidth: preview.implicitWidth
        implicitHeight: stage.barH
        opacity: isGrabbed ? 0.2 : 1

        transformOrigin: Item.Center
        SequentialAnimation on rotation {
            running: stage.active && !tile.isGrabbed && !dm.active
            loops: Animation.Infinite
            NumberAnimation { to: 1.6; duration: 120; easing.type: Easing.InOutSine }
            NumberAnimation { to: -1.6; duration: 120; easing.type: Easing.InOutSine }
        }
        onIsGrabbedChanged: if (isGrabbed) rotation = 0

        BarWidget {
            id: preview
            anchors.centerIn: parent
            widgetType: tile.widgetId
            panelWindow: stage.panelWindow
            screenName: stage.screenName
            enabled: false
        }

        MouseArea {
            id: dm
            anchors.fill: parent
            enabled: !stage.grabbing || dm.active
            hoverEnabled: true
            cursorShape: Qt.OpenHandCursor
            property bool active: false

            onPressed: active = false
            onPositionChanged: mouse => {
                const pt = mapToItem(stage, mouse.x, mouse.y);
                if (!dm.active && dm.pressed) {
                    dm.active = true;
                    BarConfig.pickUpWidget(tile.section, tile.groupIndex, tile.widgetIndex);
                    proxy.begin(pt);
                } else if (dm.active) {
                    proxy.moveTo(pt);
                }
            }
            onReleased: {
                if (dm.active) {
                    dm.active = false;
                    proxy.finish();
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.rounding.small
                color: dm.containsMouse
                    ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.16)
                    : "transparent"
            }
        }
    }

    component EditGroup: Item {
        id: eg
        property string section: ""
        property int groupIndex: 0
        property var group: ({})
        readonly property var widgetIds: group.widgets ?? []
        readonly property bool bg: group.background ?? false

        implicitWidth: egRow.implicitWidth
        implicitHeight: stage.barH
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined

        Rectangle {
            visible: eg.bg
            anchors.fill: parent
            anchors.leftMargin: -Theme.workspace.indicatorPadding + 2
            anchors.rightMargin: -Theme.workspace.indicatorPadding + 2
            radius: Theme.workspace.indicatorRadius
            color: Theme.workspace.background
        }

        Row {
            id: egRow
            anchors.centerIn: parent
            spacing: 0

            Marker { section: eg.section; kind: "widget-gap"; a: eg.groupIndex; b: 0 }

            Repeater {
                model: eg.widgetIds
                delegate: Row {
                    required property var modelData
                    required property int index
                    WidgetTile {
                        section: eg.section
                        groupIndex: eg.groupIndex
                        widgetIndex: index
                        widgetId: modelData
                    }
                    Marker { section: eg.section; kind: "widget-gap"; a: eg.groupIndex; b: index + 1 }
                }
            }
        }
    }

    component Region: Row {
        id: rg
        property string section: ""
        property var groups: []
        spacing: Theme.spacing.tiny

        Marker { section: rg.section; kind: "new-group"; a: 0; wide: true }

        Repeater {
            model: rg.groups
            delegate: Row {
                required property var modelData
                required property int index
                EditGroup { section: rg.section; groupIndex: index; group: modelData }
                Marker { section: rg.section; kind: "new-group"; a: index + 1; wide: true }
            }
        }
    }
}
