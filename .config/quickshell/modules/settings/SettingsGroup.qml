import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings
import qs.widgets

// A settings section: an "icon + title" header band, then a run of rows. Rows
// paint their own `surfaceVariant` connected rect and the segmented rounding
// (big outer corners, tiny joins) makes the run read as one grouped list
// against the window; on hover a row lifts out with a full radius + its own
// lighter tint.
//
// Rows lay out on a two-column grid so short rows pair up two to a line —
// `compact: true` on a row (or `dense: true` on the whole group) opts it in;
// `wide: true` opts a single row back out. This is what keeps a page from
// being one long linear column of full-width rows.
ColumnLayout {
    id: group

    property string caption: ""
    property string icon: ""
    // Optional dim line trailing the caption, for a unit or a short aside.
    property string hint: ""
    property bool dense: false

    // When `collapsible`, the header toggles the rows in/out of view. `forceExpand`
    // (e.g. an active search) overrides a collapsed section back open.
    property bool collapsible: false
    property bool forceExpand: false
    property bool _collapsed: false
    readonly property bool collapsed: collapsible && _collapsed && !forceExpand

    default property alias content: grid.data

    readonly property int pad: 0

    Layout.fillWidth: true
    spacing: Theme.spacing.small

    // --- section header ---------------------------------------------------
    Item {
        Layout.fillWidth: true
        Layout.bottomMargin: 1
        implicitHeight: hdr.implicitHeight
        visible: group.caption.length > 0

        SectionHeader {
            id: hdr
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            title: group.caption
            icon: group.icon
            hint: group.hint

            Text {
                visible: group.collapsible
                text: group.collapsed ? "󰅀" : "󰅃"
                font.family: Theme.font.icon
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: group.collapsible
            cursorShape: Qt.PointingHandCursor
            onClicked: group._collapsed = !group._collapsed
        }
    }

    // --- the rows --------------------------------------------------------
    // No card: each row paints its own connected rect and the segmented
    // rounding makes the run read as one grouped list. Rows meet with a small
    // gap.
    Item {
        Layout.fillWidth: true
        implicitHeight: group.collapsed ? 0 : grid.implicitHeight
        clip: true
        visible: grid.implicitHeight > 0

        Behavior on implicitHeight {
            NumberAnimation { duration: Theme.animation.fast; easing.type: Easing.OutCubic }
        }

        GridLayout {
            id: grid
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            columns: 2
            columnSpacing: Theme.spacing.tiny
            rowSpacing: Theme.spacing.tiny

            onChildrenChanged: Qt.callLater(group.relayout)
            onVisibleChildrenChanged: Qt.callLater(group.relayout)
        }
    }

    Component.onCompleted: Qt.callLater(relayout)
    onDenseChanged: Qt.callLater(relayout)

    // Tells every row it is on a shared run, applies `dense`, walks the section
    // pairing adjacent compact rows onto one grid line (a compact row with no
    // compact neighbour spans both columns rather than leaving a hole), then
    // tags each row's `blockPosition` so only the run's ends round at rest.
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

        // `lineStart[k]` — does item k begin a fresh grid line?
        const lineStart = [];
        for (let j = 0; j < items.length; j++) {
            const paired = items[j].compact === true
                && j + 1 < items.length
                && items[j + 1].compact === true;
            lineStart.push(true);
            if (paired) {
                items[j].Layout.columnSpan = 1;
                items[j + 1].Layout.columnSpan = 1;
                lineStart.push(false);
                j++;
            } else {
                items[j].Layout.columnSpan = 2;
            }
        }

        // Tag each row with where it sits in the run so it can round only the
        // group's outer corners (SettingsRow / VolumeControl / the list rows).
        let line = -1;
        const lineOf = items.map(() => 0);
        for (let j = 0; j < items.length; j++) {
            if (lineStart[j]) line++;
            lineOf[j] = line;
        }
        for (let j = 0; j < items.length; j++) {
            let pos = "middle";
            if (line === 0) pos = "single";
            else if (lineOf[j] === 0) pos = "top";
            else if (lineOf[j] === line) pos = "bottom";
            if (items[j].blockPosition !== undefined)
                items[j].blockPosition = pos;
        }
    }
}
