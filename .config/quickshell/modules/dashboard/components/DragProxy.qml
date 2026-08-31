import QtQuick
import qs.config

// The chip that follows the cursor while a dashboard tile / slider is being
// dragged. One of these lives at the top of the dashboard window and is handed
// to the grid and the slider stack, so the ghost floats above everything
// (including the ScrollView it was picked up in).
Item {
    id: proxy

    z: 10000
    width: row.implicitWidth + Theme.spacing.normal * 2
    height: 30
    visible: false

    Drag.active: visible
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    readonly property var grab: DashboardConfig.grab
    readonly property string glyph: !grab ? ""
        : grab.kind === "toggles" ? DashboardConfig.toggleIcon(grab.id)
        : DashboardConfig.sliderIcon(grab.id)
    readonly property string label: !grab ? ""
        : grab.kind === "toggles" ? DashboardConfig.toggleName(grab.id)
        : DashboardConfig.sliderName(grab.id)

    // `src` is the item the mouse coordinates came from — anywhere in the
    // window; the point is mapped into the ghost's own parent.
    function begin(src, x, y) {
        moveTo(src, x, y);
        visible = true;
    }
    function moveTo(src, x, y) {
        const p = proxy.parent.mapFromItem(src, x, y);
        proxy.x = p.x - proxy.width / 2;
        proxy.y = p.y - proxy.height / 2;
    }
    // Edit mode ending (or a slot accepting the drop) clears the grab - the
    // ghost must not outlive it.
    onGrabChanged: if (!grab) visible = false;

    function finish() {
        if (!visible) return;
        Drag.drop();
        visible = false;
        // Nothing caught it — put the entry back where it was.
        if (DashboardConfig.grab)
            DashboardConfig.cancelGrab();
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.rounding.small
        color: Theme.colors.accent
        opacity: 0.93

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.spacing.tiny

            Text {
                text: proxy.glyph
                font.family: Theme.font.icon
                font.pointSize: Theme.font.small
                color: Theme.colors.bg
            }
            Text {
                text: proxy.label
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                font.weight: Theme.font.semiBold
                color: Theme.colors.bg
            }
        }
    }
}
