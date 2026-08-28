import QtQuick
import QtQuick.Layouts
import qs.config

// Like BarPill, but with no resting background - it only fades in the same
// `Theme.colors.hover` wash on hover (the WindowTitle affordance, shared).
// Height and radius match the workspace capsule so every bar element lines up.
// Content is laid out in a horizontal RowLayout. A HoverHandler is used (not a
// MouseArea) so nested interactive children keep their own clicks.
Item {
    id: root

    default property alias content: layout.data
    property alias spacing: layout.spacing
    // Horizontal breathing room the hover wash extends past the content.
    property real hPadding: Theme.spacing.small
    readonly property bool hovered: hover.hovered

    implicitWidth: layout.implicitWidth + hPadding * 2
    implicitHeight: Theme.workspace.indicatorHeight

    Rectangle {
        anchors.fill: parent
        radius: Theme.workspace.indicatorRadius
        color: hover.hovered ? Theme.colors.hover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
    }

    HoverHandler { id: hover }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Theme.spacing.small
    }
}
