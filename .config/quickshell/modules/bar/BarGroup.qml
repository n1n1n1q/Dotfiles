import QtQuick
import qs.config

// One bar group: an optionally-backgrounded pill holding an ordered row of
// widgets. Sizes itself to its content.
Item {
    id: root

    required property var group          // { background: bool, widgets: [id...] }
    property var panelWindow: null
    property string screenName: ""

    readonly property bool hasBackground: group.background ?? false
    readonly property var widgetIds: group.widgets ?? []
    readonly property int pad: Theme.workspace.indicatorPadding

    implicitWidth: Math.max(1, row.implicitWidth + (hasBackground ? pad * 2 : 0))
    implicitHeight: Theme.workspace.indicatorHeight

    Rectangle {
        anchors.fill: parent
        visible: root.hasBackground
        radius: Theme.workspace.indicatorRadius
        color: Theme.workspace.background
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: root.widgetIds

            delegate: BarWidget {
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                widgetType: modelData
                panelWindow: root.panelWindow
                screenName: root.screenName
            }
        }
    }
}
