pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services.niri
import qs.modules.popout

// Per-output workspace row. A capsule (styled like the other bar widgets)
// holding one thin vertical bar per workspace, coloured by window state, with
// a single accent "puck" floating on top of whichever workspace is focused.
// When focus moves the puck slides to the new slot, stretching into a capsule
// that bridges the two, then contracting back into a circle on arrival.
Rectangle {
    id: root

    required property string outputName

    readonly property var realWs: NiriService.workspacesForOutput(outputName)
    readonly property int realCount: realWs.length
    readonly property int count: BarConfig.widgetSetting("workspaces", "slotCount")

    readonly property var workspaces: {
        const byIdx = new Map(realWs.map(w => [w.idx, w]))
        const slots = []
        for (let i = 1; i <= count; i++) {
            slots.push(byIdx.get(i) ?? {
                id: -i, // never matches a real workspace_id
                idx: i,
                is_focused: false
            })
        }
        return slots
    }

    readonly property int focusedIndex: workspaces.findIndex(w => w.is_focused)
    readonly property int slotStep: Theme.workspace.rectW + Theme.workspace.slotSpacing

    implicitWidth: chipRow.implicitWidth + Theme.workspace.indicatorPadding * 2
    implicitHeight: Theme.workspace.indicatorHeight
    radius: Theme.workspace.indicatorRadius
    color: Theme.workspace.background

    Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: root.workspaces

            delegate: Item {
                id: slot

                required property var modelData
                required property int index

                readonly property bool exists: (index + 1) <= root.realCount
                readonly property bool occupied: exists && NiriService.isWorkspaceOccupied(modelData.id)

                width: root.slotStep
                height: Theme.workspace.chipH

                Rectangle {
                    anchors.centerIn: parent
                    width: Theme.workspace.rectW
                    height: parent.height
                    radius: Theme.workspace.rectRadius
                    color: !slot.exists ? Theme.workspace.nonexistentBg
                        : slot.occupied ? Theme.workspace.occupiedBg
                        : Theme.workspace.availableBg

                    Behavior on color {
                        ColorAnimation { duration: Theme.animation.normal }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        PopoutController.close();
                        NiriService.focusWorkspace(slot.modelData.idx);
                    }
                }
            }
        }
    }

    // Floating focus puck ------------------------------------------------
    Item {
        anchors.fill: chipRow
        visible: root.focusedIndex >= 0

        // Where focus actually is (jumps), and a value that chases it (smooth).
        readonly property real homeCenter: root.focusedIndex >= 0
            ? root.focusedIndex * root.slotStep + root.slotStep / 2
            : animCenter
        property real animCenter: homeCenter
        onHomeCenterChanged: animCenter = homeCenter

        Behavior on animCenter {
            NumberAnimation {
                duration: Theme.animation.slow
                easing.type: Easing.InOutCubic
            }
        }

        readonly property real lo: Math.min(animCenter, homeCenter)
        readonly property real hi: Math.max(animCenter, homeCenter)

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.workspace.chipH
            radius: height / 2
            color: Theme.workspace.activeBg
            // Caps of radius chipH/2 centred on `lo` and `hi`, so it's a
            // circle when they coincide and a bridging capsule while they
            // don't.
            x: parent.lo - Theme.workspace.chipH / 2
            width: (parent.hi - parent.lo) + Theme.workspace.chipH
        }
    }
}
