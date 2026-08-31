import QtQuick
import qs.config

// Half of a tile (or of a slider row): dropping the held entry here inserts it
// at `index`. Lights up the edge it would land against, so a drop reads as
// "before this one" / "after this one" rather than "onto it".
DropArea {
    id: slot

    property string kind: "toggles"
    property int index: 0
    // left | right | top | bottom — which edge the insert bar hugs.
    property string edge: "left"

    // Only the list the held entry came from accepts it.
    enabled: DashboardConfig.grabbing && DashboardConfig.grab.kind === kind

    onDropped: drop => {
        // Accept first: dropAt reassigns the list, which rebuilds the delegate
        // this DropArea lives in - including the event we are handling.
        drop.accept();
        DashboardConfig.dropAt(slot.kind, slot.index);
    }

    readonly property bool horizontal: edge === "top" || edge === "bottom"

    Rectangle {
        visible: slot.containsDrag
        width: slot.horizontal ? slot.width : 3
        height: slot.horizontal ? 3 : slot.height
        x: slot.edge === "right" ? slot.width - width : 0
        y: slot.edge === "bottom" ? slot.height - height : 0
        radius: 1.5
        color: Theme.colors.accent
    }
}
