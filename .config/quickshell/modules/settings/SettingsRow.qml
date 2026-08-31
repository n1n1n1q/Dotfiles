import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.widgets

// One control line: a small monochrome glyph, a label (+ optional description)
// and a trailing slot holding the control itself. Rows are transparent — the
// enclosing SettingsGroup paints the single rounded card they all share — and
// only paint their own surface when dropped straight onto a page.
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
    signal clicked()

    default property alias trailing: slot.data

    readonly property bool _sub: subtitle.length > 0 && !compact

    Layout.fillWidth: true
    implicitHeight: Math.max(compact ? 36 : 42,
                             row.implicitHeight + Theme.spacing.small * 2)

    radius: Theme.rounding.large
    color: (hoverable && hover.hovered) ? Theme.colors.surfaceVariant
        : inGroup ? "transparent"
        : Theme.colors.surface

    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

    // Compact rows trade their second line for a tooltip, so nothing the wide
    // form said is actually lost.
    ToolTip.visible: root.compact && root.subtitle.length > 0 && hover.hovered
    ToolTip.text: root.subtitle
    ToolTip.delay: 400

    HoverHandler { id: hover }

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
        anchors.leftMargin: Theme.spacing.normal
        anchors.rightMargin: Theme.spacing.small
        spacing: Theme.spacing.small

        // No accent tile — the glyph carries the row on its own, the way the
        // reference does it, so a stack of rows stays quiet.
        GlyphIcon {
            visible: root.icon.length > 0
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
            text: root.icon
            font.family: Theme.font.icon
            font.pointSize: Theme.font.large
            color: Theme.colors.textSecondary
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
                color: Theme.colors.textPrimary
            }

            Text {
                visible: root._sub
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
            spacing: Theme.spacing.tiny
        }
    }
}
