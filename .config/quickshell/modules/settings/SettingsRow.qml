import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.widgets

// One control line: a small monochrome glyph, a label (+ optional description)
// and a trailing slot holding the control itself. Rows paint their own
// `surfaceVariant` connected rect — the enclosing SettingsGroup tags each with
// where it sits in the run (`blockPosition`) so only the run's outer corners
// round at rest; on hover the row lifts out with a full radius, a lighter
// tint and `z: 1`.
//
// A `compact` row is half-width, so two of them sit side by side in the
// group's two-column grid, and its `subtitle` moves into a hover tooltip.
// SettingsGroup { dense: true } flips every row it holds into that mode.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool compact: false
    // Opt a single row out of a dense group's automatic compacting.
    property bool wide: false
    // Set by the enclosing SettingsGroup — see its relayout().
    property bool inGroup: false
    property bool hoverable: false
    // Where the row sits in its group's run — set by SettingsGroup.relayout().
    // At rest a run of rows reads as one card, so only the run's outer corners
    // round; on hover the row lifts out with a full radius + its own tint.
    property string blockPosition: "single"   // top | middle | bottom | single
    signal clicked()

    default property alias trailing: slot.data

    readonly property bool _sub: subtitle.length > 0 && !compact

    Layout.fillWidth: true
    implicitWidth: row.implicitWidth + Theme.spacing.large + Theme.spacing.medium
    implicitHeight: Math.max(compact ? 44 : 60,
                             row.implicitHeight + Theme.spacing.medium * 2)

    // Grouped-list rounding: big radius on the run's outer corners, a small
    // "join" radius where rows meet. On hover the row lifts out — full big
    // radius on every corner — and takes its own lighter tint.
    readonly property int _outer: Theme.rounding.xhuge
    readonly property int _inner: Theme.rounding.connJoin
    z: hover.hovered ? 1 : 0
    topLeftRadius: (hover.hovered || blockPosition === "top" || blockPosition === "single") ? _outer : _inner
    topRightRadius: topLeftRadius
    bottomLeftRadius: (hover.hovered || blockPosition === "bottom" || blockPosition === "single") ? _outer : _inner
    bottomRightRadius: bottomLeftRadius
    color: hover.hovered ? Theme.palette.surface2 : Theme.colors.surfaceVariant

    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
    Behavior on topLeftRadius { NumberAnimation { duration: Theme.animation.fast } }
    Behavior on bottomLeftRadius { NumberAnimation { duration: Theme.animation.fast } }


    HoverHandler { id: hover }

    // A row-wide tooltip stands in for the hidden subtitle when compact.
    AppTooltip {
        visible: root.compact && root.subtitle.length > 0 && hover.hovered
        text: root.subtitle
    }

    // Declared before the content so trailing controls win the click.
    MouseArea {
        anchors.fill: parent
        enabled: root.hoverable
        cursorShape: root.hoverable ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: root.hoverable ? Qt.LeftButton : Qt.NoButton
        onClicked: root.clicked()
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.large
        anchors.rightMargin: Theme.spacing.medium
        spacing: Theme.spacing.medium

        GlyphIcon {
            visible: root.icon.length > 0
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 22
            text: root.icon
            font.family: Theme.font.icon
            font.pointSize: Theme.font.xlarge
            color: Theme.colors.textSecondary
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
                font.pointSize: Theme.font.large
                color: Theme.colors.textPrimary
            }

            Text {
                visible: root._sub
                Layout.fillWidth: true
                text: root.subtitle
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
        }

        RowLayout {
            id: slot
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.spacing.tiny
        }
    }
}
