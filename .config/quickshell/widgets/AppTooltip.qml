import QtQuick
import QtQuick.Templates as T
import qs.config
import qs.widgets

// Themed replacement for the QtQuick.Controls attached `ToolTip.*` property.
// The Basic style's default tooltip is a plain yellow-on-white box that
// clashes with everything else in the shell — and Quickshell ignores
// QT_QUICK_CONTROLS_STYLE (tried Material and a from-scratch style folder;
// both still rendered the Basic look), so the only way to theme it is to stop
// using the attached property and drop one of these in its place instead.
//
// Same shape as the attached API — `visible` / `text` / `delay` — because
// this literally *is* a `T.ToolTip` (a Popup) under the hood; declare it as a
// child of the hovered item and it centres itself below its parent.
T.ToolTip {
    id: root

    x: parent ? Math.round((parent.width - implicitWidth) / 2) : 0
    // Opens downward — every remaining caller lives in or just below the bar,
    // and the bar's own PanelWindow is too thin for a tooltip to fit above
    // its anchor without being clipped by the surface edge.
    y: parent ? parent.height + 8 : 0

    margins: 10
    padding: 0
    delay: 400

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent | T.Popup.CloseOnReleaseOutsideParent

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animation.fast }
            NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: Theme.animation.fast; easing.type: Easing.OutCubic }
        }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: Theme.animation.instant }
    }

    contentItem: Text {
        text: root.text
        font.family: Theme.font.main
        font.pointSize: Theme.font.small
        wrapMode: Text.Wrap
        color: Theme.colors.textPrimary
        leftPadding: Theme.spacing.normal
        rightPadding: Theme.spacing.normal
        topPadding: Theme.spacing.small
        bottomPadding: Theme.spacing.small
    }

    background: Rectangle {
        radius: Theme.rounding.control
        color: Theme.colors.surface
        border.width: 1
        border.color: Theme.colors.hairline

        SoftShadow { spread: 14; strength: 0.4 }
    }
}
