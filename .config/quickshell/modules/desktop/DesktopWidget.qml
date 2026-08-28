import QtQuick
import qs.config

// One placed desktop widget: loads the right visual by `model.type`, positions
// it at `model.x/y`, and (in edit mode) lets it be dragged to move and its
// corner dragged to resize. Holding Shift while moving snaps to an 8px grid
// and to alignment lines (screen edges / centre / thirds and other widgets'
// edges), publishing the matched guides upward.
Item {
    id: root

    required property var model          // { id, type, screen, x, y, props }
    property Item area: null             // drag coordinate space (DesktopLayer content)
    property var publishGuides: null     // function([{o:"v"|"h", p:px}])
    property var otherRects: null        // function() -> [{x,y,w,h}]
    property bool shiftHeld: false        // driven by DesktopLayer's key catcher

    readonly property bool editing: DesktopConfig.editMode
    readonly property bool selected: DesktopConfig.selectedId === model.id
    readonly property string scaleKey: model.type === "clock" ? "fontScale" : "scale"

    property real localX: model.x
    property real localY: model.y
    property real scaleOverride: -1
    onModelChanged: { localX = model.x; localY = model.y; }

    // props with a live size override applied while the corner is dragged
    readonly property var effProps: {
        const base = model.props ?? ({});
        if (scaleOverride < 0)
            return base;
        let o = {};
        for (const k in base) o[k] = base[k];
        o[scaleKey] = scaleOverride;
        return o;
    }

    x: localX
    y: localY
    width: loader.item ? loader.item.implicitWidth : 0
    height: loader.item ? loader.item.implicitHeight : 0

    // gentle jiggle while editing (unless this one is being dragged/placed)
    transformOrigin: Item.Center
    SequentialAnimation on rotation {
        running: root.editing && !dragArea.pressed
            && !resizeMouse.pressed && DesktopConfig.grabbedId !== root.model.id
        loops: Animation.Infinite
        NumberAnimation { to: 1.1; duration: 130; easing.type: Easing.InOutSine }
        NumberAnimation { to: -1.1; duration: 130; easing.type: Easing.InOutSine }
        onStopped: root.rotation = 0
    }

    Loader {
        id: loader
        sourceComponent: {
            switch (root.model.type) {
            case "clock": return clockC;
            case "stats": return statsC;
            case "media": return mediaC;
            default:      return null;
            }
        }
    }
    Component { id: clockC; ClockWidget { props: root.effProps } }
    Component { id: statsC; DesktopStatsWidget { props: root.effProps } }
    Component { id: mediaC; DesktopMediaWidget { props: root.effProps } }

    // --- edit affordances -------------------------------------------------
    // Only the selected widget shows the full chrome; the rest get a faint
    // outline on hover so you can tell what's grabbable.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        visible: root.editing
        radius: Theme.rounding.small
        color: (root.selected && dragArea.pressed)
            ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.14)
            : "transparent"
        border.width: root.selected ? 1 : 1
        border.color: root.selected
            ? Theme.colors.accent
            : (dragArea.containsMouse
                ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.4)
                : "transparent")
    }

    // delete
    Rectangle {
        visible: root.editing && root.selected
        anchors.horizontalCenter: parent.right
        anchors.verticalCenter: parent.top
        width: 20
        height: 20
        radius: 10
        color: delMouse.containsMouse ? Theme.colors.error : Theme.colors.surface
        border.width: 1
        border.color: Theme.colors.error
        Text {
            anchors.centerIn: parent
            text: "󰅖"
            font.family: Theme.font.icon
            font.pointSize: Theme.font.small
            color: delMouse.containsMouse ? Theme.colors.bg : Theme.colors.error
        }
        MouseArea {
            id: delMouse
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: DesktopConfig.remove(root.model.id)
        }
    }

    // resize (drag the corner)
    Rectangle {
        id: resizeHandle
        visible: root.editing && root.selected
        anchors.horizontalCenter: parent.right
        anchors.verticalCenter: parent.bottom
        width: 16
        height: 16
        radius: 4
        color: resizeMouse.pressed ? Theme.colors.accent
            : (resizeMouse.containsMouse ? Theme.colors.accent : Theme.colors.surface)
        border.width: 1
        border.color: Theme.colors.accent
        Text {
            anchors.centerIn: parent
            text: "󰩨"
            font.family: Theme.font.icon
            font.pointSize: Theme.font.tiny
            color: (resizeMouse.pressed || resizeMouse.containsMouse) ? Theme.colors.bg : Theme.colors.accent
        }

        MouseArea {
            id: resizeMouse
            anchors.fill: parent
            anchors.margins: -6
            enabled: root.editing
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            property real startDiag
            property real startScale

            onPressed: mouse => {
                const p = mapToItem(root.area, mouse.x, mouse.y);
                startDiag = Math.max(8, Math.hypot(p.x - root.localX, p.y - root.localY));
                startScale = (root.model.props ?? ({}))[root.scaleKey] ?? 1.0;
                root.scaleOverride = startScale;
            }
            onPositionChanged: mouse => {
                if (!pressed) return;
                const p = mapToItem(root.area, mouse.x, mouse.y);
                const d = Math.hypot(p.x - root.localX, p.y - root.localY);
                let ns = startScale * (d / startDiag);
                root.scaleOverride = Math.max(0.5, Math.min(3.0, Math.round(ns * 20) / 20));
            }
            onReleased: {
                DesktopConfig.setProp(root.model.id, root.scaleKey, root.scaleOverride);
                root.scaleOverride = -1;
            }
        }
    }

    // move (drag the body)
    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: root.editing
        hoverEnabled: root.editing
        cursorShape: Qt.SizeAllCursor
        property point startMouse
        property real startX
        property real startY

        onPressed: mouse => {
            DesktopConfig.selectedId = root.model.id;
            const p = mapToItem(root.area, mouse.x, mouse.y);
            startMouse = Qt.point(p.x, p.y);
            startX = root.localX;
            startY = root.localY;
        }
        onPositionChanged: mouse => {
            if (!pressed || !root.area) return;   // hoverEnabled also fires this on plain moves
            const p = mapToItem(root.area, mouse.x, mouse.y);
            let nx = startX + (p.x - startMouse.x);
            let ny = startY + (p.y - startMouse.y);

            if (root.shiftHeld) {
                const s = root.computeSnap(nx, ny);
                nx = s.x; ny = s.y;
                if (root.publishGuides) root.publishGuides(s.guides);
            } else if (root.publishGuides) {
                root.publishGuides([]);
            }

            root.localX = Math.max(0, Math.min(nx, root.area.width - root.width));
            root.localY = Math.max(0, Math.min(ny, root.area.height - root.height));
        }
        onReleased: {
            if (root.publishGuides) root.publishGuides([]);
            DesktopConfig.move(root.model.id, root.localX, root.localY);
        }
    }

    function computeSnap(nx, ny) {
        const grid = 8;
        const thr = 8;
        const W = root.area.width, H = root.area.height;
        const w = root.width, h = root.height;
        const m = 24;

        let vLines = [m, W / 3, W / 2, 2 * W / 3, W - m];
        let hLines = [m, H / 3, H / 2, 2 * H / 3, H - m];
        if (root.otherRects) {
            for (const r of root.otherRects()) {
                vLines.push(r.x, r.x + r.w / 2, r.x + r.w);
                hLines.push(r.y, r.y + r.h / 2, r.y + r.h);
            }
        }

        function best(pos, size, lines) {
            let out = null, guide = null, bd = thr;
            for (const L of lines) {
                for (const off of [0, size / 2, size]) {
                    const d = Math.abs((pos + off) - L);
                    if (d < bd) { bd = d; out = L - off; guide = L; }
                }
            }
            return { v: out, guide: guide };
        }

        const bx = best(nx, w, vLines);
        const by = best(ny, h, hLines);
        const guides = [];
        if (bx.guide !== null) guides.push({ o: "v", p: bx.guide });
        if (by.guide !== null) guides.push({ o: "h", p: by.guide });

        return {
            x: bx.v !== null ? bx.v : Math.round(nx / grid) * grid,
            y: by.v !== null ? by.v : Math.round(ny / grid) * grid,
            guides: guides
        };
    }
}
