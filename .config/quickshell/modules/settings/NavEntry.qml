import QtQuick
import QtQuick.Layouts
import qs.config

// One sidebar navigation row, styled like a bar pill. Entries in a group sit
// flush (SettingsGroup spacing 0) and only the run's ends round off, via
// `blockPosition` — the segmented-list look.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool selected: false
    // top | middle | bottom | single — assigned by the parent SettingsGroup.
    property string blockPosition: "single"
    signal clicked()

    readonly property int _r: Theme.workspace.indicatorRadius
    readonly property bool _roundTop: blockPosition === "top" || blockPosition === "single"
    readonly property bool _roundBottom: blockPosition === "bottom" || blockPosition === "single"

    Layout.fillWidth: true
    implicitHeight: 56

    // Bar-pill palette: faint resting fill, brighter on hover, accent-tinted
    // when active.
    readonly property color _rest: Qt.rgba(Theme.palette.surface0.r,
                                           Theme.palette.surface0.g,
                                           Theme.palette.surface0.b, 0.45)
    readonly property color _accentWash: Qt.rgba(Theme.colors.accent.r,
                                                 Theme.colors.accent.g,
                                                 Theme.colors.accent.b, 0.16)
    color: selected ? _accentWash
        : mouse.containsMouse ? Theme.colors.surfaceVariant
        : _rest
    topLeftRadius: _roundTop ? _r : 0
    topRightRadius: _roundTop ? _r : 0
    bottomLeftRadius: _roundBottom ? _r : 0
    bottomRightRadius: _roundBottom ? _r : 0

    Behavior on color {
        ColorAnimation { duration: Theme.animation.fast }
    }

    // Accent bar on the left edge of the active entry.
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height - Theme.spacing.normal
        radius: width / 2
        color: Theme.colors.accent
        opacity: root.selected ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.normal
        anchors.rightMargin: Theme.spacing.normal
        spacing: Theme.spacing.normal

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 34
            implicitHeight: 34
            radius: height / 2
            color: root.selected ? Theme.colors.accent : Theme.colors.surfaceVariant

            Behavior on color {
                ColorAnimation { duration: Theme.animation.fast }
            }

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: Theme.font.icon
                font.pointSize: Theme.font.large
                color: root.selected ? Theme.colors.bg : Theme.colors.textSecondary
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: -1

            Text {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.bar.fontSize
                font.weight: root.selected ? Theme.font.semiBold : Theme.font.mediumWeight
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
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
