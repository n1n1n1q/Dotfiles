import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

// One sidebar row: a glyph and a label in a full-round pill. The active entry
// is a solid accent pill; everything else is bare until hovered. Subtitles
// live in the tooltip so the rail stays one line per entry.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool selected: false
    // Icon-only rail — the label fades out and the glyph centres.
    property bool collapsed: false
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: 38
    radius: height / 2

    color: selected ? Theme.colors.accent
        : hover.hovered ? Theme.colors.surface
        : "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.animation.fast }
    }

    ToolTip.visible: hover.hovered && (root.collapsed || root.subtitle.length > 0)
    ToolTip.text: root.collapsed && root.subtitle.length > 0
        ? root.title + " — " + root.subtitle
        : root.collapsed ? root.title : root.subtitle
    ToolTip.delay: 400

    HoverHandler { id: hover }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.collapsed ? 0 : Theme.spacing.normal
        anchors.rightMargin: root.collapsed ? 0 : Theme.spacing.normal
        spacing: Theme.spacing.small

        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: root.collapsed ? root.width : 20
            horizontalAlignment: Text.AlignHCenter
            text: root.icon
            font.family: Theme.font.icon
            font.pointSize: Theme.font.large
            color: root.selected ? Theme.colors.bg : Theme.colors.textSecondary

            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
        }

        Text {
            Layout.fillWidth: true
            visible: !root.collapsed
            opacity: root.collapsed ? 0 : 1
            text: root.title
            elide: Text.ElideRight
            font.family: Theme.font.main
            font.pointSize: Theme.font.medium
            font.weight: root.selected ? Theme.font.mediumWeight : Theme.font.regular
            color: root.selected ? Theme.colors.bg : Theme.colors.textPrimary

            Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
