import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings
import qs.widgets

// A settings section: an "icon + title" header band, then one rounded card
// holding every row in the section. Rows inside share the card's surface — no
// per-row panels, no dividers — and lay out on a two-column grid so short
// toggle rows pair up two to a line.
//
// `dense: true` compacts every row it holds (half width, description moved to
// a hover tooltip); a row can opt back out with `wide: true`.
ColumnLayout {
    id: group

    property string caption: ""
    property string icon: ""
    // Optional dim line trailing the caption, for a unit or a short aside.
    property string hint: ""
    property bool dense: false

    default property alias content: grid.data

    readonly property int pad: 6

    Layout.fillWidth: true
    spacing: Theme.spacing.tiny

    // --- section header ---------------------------------------------------
    SectionHeader {
        visible: group.caption.length > 0
        Layout.bottomMargin: 1
        title: group.caption
        icon: group.icon
        hint: group.hint
    }

    // --- the card ---------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: grid.implicitHeight + group.pad * 2
        // Hidden while the section is empty (a Repeater that produced nothing)
        // so no bare rounded blob is left behind.
        visible: grid.implicitHeight > 0
        radius: Theme.rounding.huge
        color: Theme.colors.surface

        GridLayout {
            id: grid
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: group.pad
            columns: 2
            columnSpacing: group.pad
            rowSpacing: 1

            onChildrenChanged: Qt.callLater(group.relayout)
            onVisibleChildrenChanged: Qt.callLater(group.relayout)
        }
    }

    Component.onCompleted: Qt.callLater(relayout)
    onDenseChanged: Qt.callLater(relayout)

    // Tells every row it is on a shared card, applies `dense`, then walks the
    // section pairing adjacent compact rows into one grid line. A compact row
    // with no compact neighbour spans both columns rather than leaving a hole.
    function relayout() {
        let items = [];
        for (let i = 0; i < grid.children.length; i++) {
            const c = grid.children[i];
            // Skip Repeaters and other zero-sized helpers — the grid ignores
            // them too, and giving them a span would open an empty line.
            if (!c || !c.visible || (c.implicitHeight <= 0 && c.implicitWidth <= 0))
                continue;
            items.push(c);
        }

        for (const c of items) {
            if (c.inGroup !== undefined)
                c.inGroup = true;
            if (group.dense && c.compact !== undefined && !c.wide)
                c.compact = true;
            c.Layout.fillWidth = true;
        }

        for (let j = 0; j < items.length; j++) {
            const paired = items[j].compact === true
                && j + 1 < items.length
                && items[j + 1].compact === true;
            if (paired) {
                items[j].Layout.columnSpan = 1;
                items[j + 1].Layout.columnSpan = 1;
                j++;
            } else {
                items[j].Layout.columnSpan = 2;
            }
        }
    }
}
