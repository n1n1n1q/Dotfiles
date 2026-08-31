import QtQuick
import qs.config

// The dashboard slider's clothes with none of its input handling. What each
// style draws isn't decided here — DashboardConfig.sliderStyles carries a flag
// per shape and this reads them, so adding a sixth style is one line in the
// catalogue rather than a new string to match in four places:
//
//   (none)      a chunky filled capsule
//   handle      a round knob riding a thin track
//   split       the level and what's left of it as two capsules with a gap
//   iconInside  the caller's glyph moves into the bar's leading end, and the
//               bar grows tall enough to hold it
//
// DashSlider paints its Slider with one of these and the OSD draws one
// straight, so the pill that drops under the bar and the row in the panel are
// recognisably the same control.
Item {
    id: root

    // 0..1; anything outside that is clamped rather than overflowing the track.
    property real value: 0
    // One of DashboardConfig.sliderStyles; anything else draws as "progress".
    property string style: "progress"
    property color fillColor: Theme.colors.accent
    // A split remainder reads as the rest of *this* level rather than as the
    // surface behind one, so it dims the fill instead of tinting the row.
    property color trackColor: root.split
        ? Qt.rgba(fillColor.r, fillColor.g, fillColor.b, 0.28)
        : Qt.rgba(Theme.colors.surfaceVariant.r,
                  Theme.colors.surfaceVariant.g,
                  Theme.colors.surfaceVariant.b, 0.6)
    property color handleColor: Theme.colors.text
    // The glyph for the icon-inside styles; ignored by the rest, which leave
    // the caller to keep its own icon beside the bar.
    property string icon: ""
    property color iconColor: Theme.colors.textPrimary
    // The level slides under the glyph almost immediately, so it is drawn a
    // second time in this colour over the fill to stay legible against it.
    property color iconOnFillColor: Theme.colors.bg
    // Ease the fill towards a new value. Off by default: under a pointer that
    // is dragging it, an eased fill only trails behind the cursor. The OSD,
    // which is handed finished values a keybind already stepped, turns it on.
    property bool animated: false

    // The catalogue entry is the single description of this shape — callers
    // read the same flags to lay out around the bar.
    readonly property var shape: DashboardConfig.sliderStyleEntry(style)
    readonly property bool iconInside: shape.iconInside === true
    readonly property bool split: shape.split === true
    // Everything but the handle style draws as a filled capsule.
    readonly property bool progress: shape.handle !== true

    readonly property real position: Math.max(0, Math.min(1, value))
    readonly property int handleSize: Theme.sizes.levelHandle
    // The glyph sits centred in a leading square as tall as the bar, so the
    // room it takes is the one thing a caller has to know about it.
    readonly property real iconExtent: iconInside ? track.height : 0
    // The gap belongs to the pair. At either end of the range one capsule is
    // gone, and the survivor should span the whole bar rather than sit inset
    // from an edge with nothing across from it.
    readonly property real splitGap:
        split && position > 0 && position < 1 ? Theme.sizes.levelGap : 0

    implicitWidth: 200
    // Never shorter than the handle, even in the styles that don't draw one,
    // so flipping between them can't make the row jump.
    implicitHeight: Math.max(track.height, handleSize)

    Rectangle {
        id: track

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        // Chunky capsules by default — a thin hairline track reads as a
        // scrollbar next to the rest of the shell. A glyph inside needs the
        // room to sit in; a split pair goes slim, because there the gap is
        // what has to read and a thick bar swallows it.
        height: root.iconInside ? Theme.sizes.levelInline
            : root.split ? Theme.sizes.levelSplit
            : root.progress ? Theme.sizes.levelThick
            : Theme.sizes.levelThin
        radius: height / 2
        // A split bar has nothing running the full width behind the level —
        // its remainder is a capsule of its own, starting past the gap.
        color: root.split ? "transparent" : root.trackColor

        Behavior on height { NumberAnimation { duration: Theme.animation.fast } }

        // What is left of the level, off on its own past the gap. It rides the
        // fill's width, so easing the fill eases this too. Declared first so
        // the glyph below stays on top of it: where the level hasn't reached,
        // this capsule is what the glyph has to read against.
        Rectangle {
            visible: root.split
            x: fill.width + root.splitGap
            width: Math.max(0, parent.width - x)
            height: parent.height
            radius: parent.radius
            color: root.trackColor

            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
        }

        // Declared before the fill, which is opaque: what the level has
        // reached covers this copy, and the copy inside the fill takes over.
        Text {
            visible: root.iconInside
            width: root.iconExtent
            height: parent.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root.icon
            font.family: Theme.font.icon
            font.pointSize: Theme.font.xlarge
            color: root.iconColor
        }

        Rectangle {
            id: fill

            // The gap is carved out of the bar rather than laid over it, so
            // the two capsules together still measure the level honestly.
            width: root.position * (parent.width - root.splitGap)
            height: parent.height
            radius: parent.radius
            color: root.fillColor
            // Clips the glyph below to the part of it the level has swallowed.
            clip: root.iconInside

            Behavior on width {
                enabled: root.animated
                NumberAnimation { duration: Theme.animation.fast }
            }
            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

            // The fill's own right edge is square so it reads as a level, not
            // a pill, once the bar is thick — but only while it is genuinely
            // partway across. Any shorter than its own height and the square
            // eats the leading cap too, leaving a rectangle; any closer than a
            // corner to the far end and it squares off the end of the bar
            // itself. Both edges of the travel want the plain capsule back.
            //
            // Both tests are on the fill's live width rather than on `value`,
            // because the fill eases towards a new level and the two disagree
            // for as long as that takes: keyed to the value, stepping down off
            // maximum squares the bar off for the whole animation, while the
            // fill still spans the track.
            //
            // A split bar never wants this at all: its two rounded ends are
            // what the gap between them reads against.
            Rectangle {
                visible: root.progress && !root.split
                    && fill.width > track.height
                    && track.width - fill.width > track.radius
                anchors.right: parent.right
                width: parent.radius
                height: parent.height
                color: parent.color
            }

            Text {
                visible: root.iconInside
                width: root.iconExtent
                height: parent.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.icon
                font.family: Theme.font.icon
                font.pointSize: Theme.font.xlarge
                color: root.iconOnFillColor
            }
        }
    }

    // A filled capsule is its own indicator — the handle only turns up on the
    // thin track.
    Rectangle {
        visible: !root.progress
        x: root.position * (root.width - width)
        y: (root.height - height) / 2
        width: root.handleSize
        height: root.handleSize
        radius: height / 2
        color: root.handleColor

        Behavior on x {
            enabled: root.animated
            NumberAnimation { duration: Theme.animation.fast }
        }
    }
}
