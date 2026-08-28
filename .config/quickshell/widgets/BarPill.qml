import QtQuick
import QtQuick.Layouts
import qs.config

// Shared "pill" container used across the bar's status widgets: a rounded,
// themed capsule that sizes itself to whatever's laid out inside it.
// Extracted from what used to be near-identical boilerplate repeated in
// WorkspaceIndicator, TimeWidget, BatteryWidget and VolumeWidget.
Rectangle {
    id: root

    default property alias content: layout.data
    property alias spacing: layout.spacing

    implicitWidth: layout.implicitWidth + Theme.workspace.indicatorPadding * 2
    implicitHeight: Theme.workspace.indicatorHeight
    radius: Theme.workspace.indicatorRadius
    color: Theme.workspace.background

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Theme.spacing.small
    }
}
