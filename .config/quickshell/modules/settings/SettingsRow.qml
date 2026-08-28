import QtQuick
import QtQuick.Layouts
import qs.config

// One "sub-block" in a SettingsGroup: its own surface panel with an icon tile,
// a title (+ optional subtitle) and a trailing control slot. SettingsGroup sets
// `blockPosition`, which decides which corners are rounded so a stack of these
// reads as a segmented list (ends rounded, middles square).
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    // top | middle | bottom | single  — assigned by the parent SettingsGroup.
    property string blockPosition: "single"
    property bool hoverable: false
    signal clicked()

    default property alias trailing: slot.data

    readonly property int _r: Theme.workspace.indicatorRadius
    readonly property bool _roundTop: blockPosition === "top" || blockPosition === "single"
    readonly property bool _roundBottom: blockPosition === "bottom" || blockPosition === "single"

    Layout.fillWidth: true
    implicitHeight: Math.max(60, row.implicitHeight + Theme.spacing.normal * 2)

    color: (hoverable && mouse.containsMouse) ? Theme.colors.surfaceVariant : Theme.colors.surface
    topLeftRadius: _roundTop ? _r : 0
    topRightRadius: _roundTop ? _r : 0
    bottomLeftRadius: _roundBottom ? _r : 0
    bottomRightRadius: _roundBottom ? _r : 0

    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

    // Hairline divider between stacked rows in a run (drawn on the bottom edge
    // of all but the last row — no doubling at the seam).
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.spacing.normal
        anchors.rightMargin: Theme.spacing.normal
        height: 1
        visible: root.blockPosition === "top" || root.blockPosition === "middle"
        color: Qt.rgba(Theme.colors.borderSubtle.r, Theme.colors.borderSubtle.g,
                       Theme.colors.borderSubtle.b, 0.5)
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.normal
        anchors.rightMargin: Theme.spacing.normal
        anchors.topMargin: Theme.spacing.small
        anchors.bottomMargin: Theme.spacing.small
        spacing: Theme.spacing.normal

        Rectangle {
            visible: root.icon.length > 0
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 34
            implicitHeight: 34
            radius: Theme.rounding.small
            color: Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g,
                           Theme.colors.accent.b, 0.16)

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: Theme.font.icon
                font.pointSize: Theme.font.large
                color: Theme.colors.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.font.medium
                font.weight: Theme.font.mediumWeight
                color: Theme.colors.textPrimary
            }

            Text {
                visible: root.subtitle.length > 0
                Layout.fillWidth: true
                text: root.subtitle
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
        }

        RowLayout {
            id: slot
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.spacing.small
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.hoverable
        hoverEnabled: root.hoverable
        cursorShape: root.hoverable ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: root.hoverable ? Qt.LeftButton : Qt.NoButton
        onClicked: root.clicked()
    }
}
