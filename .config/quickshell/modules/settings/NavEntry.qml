import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.widgets

// One sidebar entry, Caelestia-"Nexus" style: a circular icon chip beside a
// two-line label (title + description). Entries in a nav group sit close and
// share one rounded block — `blockPosition` rounds only the run's ends; the
// selected entry lifts out with a full radius and an accent wash.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool selected: false
    // Icon-only rail — the label fades out and the chip centres.
    property bool collapsed: false
    // top | middle | bottom | single — set by the sidebar per nav group.
    property string blockPosition: "single"
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: Math.max(64, row.implicitHeight + Theme.spacing.small * 2)

    readonly property int _outer: Theme.rounding.xhuge
    readonly property int _inner: Theme.rounding.connJoin
    readonly property bool _top: selected || blockPosition === "top" || blockPosition === "single"
    readonly property bool _bot: selected || blockPosition === "bottom" || blockPosition === "single"
    topLeftRadius: _top ? _outer : _inner
    topRightRadius: _top ? _outer : _inner
    bottomLeftRadius: _bot ? _outer : _inner
    bottomRightRadius: _bot ? _outer : _inner

    color: selected ? Theme.colors.accentTintStrong
        : hover.hovered ? Theme.palette.surface2
        : Theme.colors.surfaceVariant

    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
    Behavior on topLeftRadius { NumberAnimation { duration: Theme.animation.fast } }
    Behavior on bottomLeftRadius { NumberAnimation { duration: Theme.animation.fast } }

    HoverHandler { id: hover }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: root.collapsed ? 0 : Theme.spacing.normal
        anchors.rightMargin: root.collapsed ? 0 : Theme.spacing.large
        spacing: Theme.spacing.normal

        // Circular icon chip.
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: root.collapsed ? 0 : 0
            implicitWidth: 40
            implicitHeight: 40
            radius: width / 2
            color: root.selected ? Theme.colors.accent
                : Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.16)

            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

            GlyphIcon {
                anchors.centerIn: parent
                text: root.icon
                font.family: Theme.font.icon
                font.pointSize: Theme.font.large
                color: root.selected ? Theme.colors.bg : Theme.colors.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: !root.collapsed
            opacity: root.collapsed ? 0 : 1
            spacing: -1

            Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }

            Text {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.font.large
                font.weight: root.selected ? Theme.font.semiBold : Theme.font.mediumWeight
                color: Theme.colors.textPrimary
            }

            Text {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: root.subtitle
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: root.selected ? Theme.colors.textSecondary : Theme.colors.textTertiary
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
