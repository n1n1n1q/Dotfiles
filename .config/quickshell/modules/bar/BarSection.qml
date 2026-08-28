import QtQuick
import qs.config

// One of the bar's three regions. Groups lay out in a row (natural
// `spacing.medium` gaps). If one group has `pin: true` it is anchored dead
// centre of the bar and the other groups flank it — those before it end at the
// pin's left edge, those after start at its right.
Item {
    id: root

    property string align: "left"       // left | center | right
    property var groups: []
    property var panelWindow: null
    property string screenName: ""

    anchors.fill: parent

    readonly property int gap: Theme.spacing.medium
    readonly property int leftPad: Theme.spacing.medium
    readonly property int rightPad: Theme.spacing.medium + Theme.spacing.normal
    readonly property var emptyGroup: ({ "widgets": [] })

    readonly property int pinIndex: {
        for (let i = 0; i < groups.length; i++)
            if (groups[i] && groups[i].pin)
                return i;
        return -1;
    }
    readonly property bool pinned: pinIndex >= 0
    readonly property var beforeGroups: pinned ? groups.slice(0, pinIndex) : groups
    readonly property var afterGroups: pinned ? groups.slice(pinIndex + 1) : []

    component GroupRow: Repeater {
        delegate: BarGroup {
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            group: modelData
            panelWindow: root.panelWindow
            screenName: root.screenName
        }
    }

    // The pinned group, dead centre of the bar.
    BarGroup {
        id: pinGroup
        visible: root.pinned
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        group: root.pinned ? root.groups[root.pinIndex] : root.emptyGroup
        panelWindow: root.panelWindow
        screenName: root.screenName
    }

    // Groups before the pin (or all groups, when nothing is pinned).
    Row {
        id: beforeRow
        spacing: root.gap
        anchors.verticalCenter: parent.verticalCenter

        anchors.left: (!root.pinned && root.align === "left") ? parent.left : undefined
        anchors.leftMargin: root.leftPad
        anchors.horizontalCenter: (!root.pinned && root.align === "center") ? parent.horizontalCenter : undefined
        anchors.right: root.pinned ? pinGroup.left
            : (root.align === "right" ? parent.right : undefined)
        anchors.rightMargin: root.pinned ? root.gap : root.rightPad

        GroupRow { model: root.beforeGroups }
    }

    // Groups after the pin.
    Row {
        id: afterRow
        visible: root.pinned
        spacing: root.gap
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: pinGroup.right
        anchors.leftMargin: root.gap

        GroupRow { model: root.afterGroups }
    }
}
