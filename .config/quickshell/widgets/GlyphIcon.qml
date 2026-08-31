import QtQuick
import qs.config

// One Nerd-Font glyph in a cell that doesn't change size when the glyph does.
//
// Nerd Font gives every icon the same one-cell advance, but the icon artwork
// is drawn wider than that cell and anchored to its left edge, so Qt stretches
// a plain Text out to cover the overflow. At the bar's size the sound glyph
// measures 14.9px on volume-low, 17.9px on volume-high and 18.9px on mute — a
// 4px swing that a RowLayout dutifully passes on to every element beside it.
// Changing the volume should not shuffle the rest of the row sideways.
//
// So the cell is measured once from the widest glyph it will ever be asked to
// draw (`glyphs`), and each glyph is then placed by its ink rather than by its
// advance, which keeps every state centred on the same point instead of
// letting the wide ones spill to the right.
Item {
    id: root

    // The glyph to draw right now.
    property string text: ""
    // Every glyph this cell can be asked to draw. Measuring the whole set
    // instead of the one on show is the entire point — it is what stops the
    // cell resizing when the state changes. Only matters where the cell sizes
    // itself: given an explicit width (a layout column, a fixed square) the
    // ink centring below is enough on its own. Defaults to the current glyph.
    property var glyphs: []
    property alias font: label.font
    property color color: Theme.colors.textPrimary
    // Extra air on either side of the cell.
    property real padding: 0

    readonly property var measured: glyphs.length > 0 ? glyphs
        : (text === "" ? [] : [text])

    // The widest of `measured`, ink and advance both taken into account.
    property real cellWidth: 0

    function remeasure() {
        let w = 0;
        for (const g of root.measured) {
            sizer.text = g;
            w = Math.max(w, sizer.tightBoundingRect.width, sizer.advanceWidth);
        }
        cellWidth = Math.ceil(w);
    }

    onMeasuredChanged: remeasure()
    Component.onCompleted: remeasure()

    implicitWidth: cellWidth + padding * 2
    // From the font rather than from the Text, which grows for a tall glyph
    // the same way it grows for a wide one.
    implicitHeight: fm.height

    // Sizes the cell. Driven by hand from remeasure() so that walking the
    // glyph set can't read back into a binding on its own result.
    TextMetrics {
        id: sizer
        font: label.font
        onFontChanged: root.remeasure()
    }

    // The ink of the glyph on show, which is what the eye lines up.
    TextMetrics {
        id: ink
        font: label.font
        text: root.text
    }

    FontMetrics { id: fm; font: label.font }

    Text {
        id: label

        text: root.text
        color: root.color
        x: Math.round((root.width - ink.tightBoundingRect.width) / 2
            - ink.tightBoundingRect.x)
        y: Math.round((root.height - implicitHeight) / 2)
    }
}
