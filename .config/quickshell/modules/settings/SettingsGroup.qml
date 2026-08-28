import QtQuick
import QtQuick.Layouts
import qs.config

// A stack of SettingsRow "sub-blocks" with a small gap between them. Assigns
// each visible row a `blockPosition` so the first/last get rounded outer
// corners and the middles stay square (segmented-list look). Sections are
// separated by the surrounding SettingsPage column's spacing alone — no
// header text.
ColumnLayout {
    id: group

    // Kept as a harmless no-op so old call sites don't error; not rendered.
    property string caption: ""
    // Plain non-row children (a Text note, a Slider) can be dropped in too; they
    // just don't get a blockPosition.
    default property alias content: group.data

    Layout.fillWidth: true
    spacing: Theme.spacing.tiny

    function relayout() {
        let rows = [];
        for (let i = 0; i < group.children.length; i++) {
            let c = group.children[i];
            if (c.blockPosition !== undefined && c.visible)
                rows.push(c);
        }
        for (let j = 0; j < rows.length; j++) {
            rows[j].blockPosition = rows.length === 1 ? "single"
                : j === 0 ? "top"
                : j === rows.length - 1 ? "bottom"
                : "middle";
        }
    }

    Component.onCompleted: Qt.callLater(relayout)
    onChildrenChanged: Qt.callLater(relayout)
    onVisibleChildrenChanged: Qt.callLater(relayout)
}
