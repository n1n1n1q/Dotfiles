import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.config

Scope {
    // Configuration
    readonly property int frameRounding: 60   // fixed corner-window box size
    readonly property int innerRounding: 34   // smaller black "screen rounding" radius, nested on top
    readonly property int barHeight: Theme.bar.height
    // Shared with Bar.qml, whose own bottom edge is styled to be this same
    // color/thickness - that's the frame's top run, so there's nothing
    // separate to keep in sync here beyond referencing the same constants.
    readonly property int frameCornerRadius: Theme.frame.cornerRadius
    readonly property color frameColor: Theme.frame.color
    readonly property color innerFrameColor: Theme.frame.innerColor
    readonly property int edgeThickness: Theme.frame.thickness
    // The bottom corner's actual content-side curvature: FrameCornerPiece is
    // a border.width-thick ring, so its inner (content) edge sits one
    // border-width inside the outer radius - not at frameCornerRadius itself.
    // The top fillet (BarFillet) is a plain filled wedge, not a ring, so it
    // has to be told this same radius explicitly to curve the same amount as
    // the bottom - otherwise "same corner radius" on paper still reads as a
    // tighter curve on one side and a gentler one on the other.
    readonly property int contentCornerRadius: frameCornerRadius - edgeThickness

    // Cross-compositor fullscreen tracking via wlr-foreign-toplevel-management
    // (Quickshell.Wayland's ToplevelManager) rather than niri's own IPC - this
    // niri build doesn't expose an is_fullscreen field over `niri msg -j
    // windows` at all, whereas the toplevel-management protocol reports it
    // directly per window, per screen. Drives hiding the frame's border while
    // a window is fullscreen; the black screen-rounder corners are meant to
    // stay above everything regardless and never consult this.
    readonly property var fullscreenScreens: {
        const screens = new Set()
        for (const toplevel of ToplevelManager.toplevels.values) {
            if (toplevel.fullscreen) {
                for (const screen of toplevel.screens) screens.add(screen)
            }
        }
        return screens
    }

    function isFrameHidden(screen) {
        return fullscreenScreens.has(screen)
    }

    // This is the exact ShapePath/PathAngleArc construction the original
    // per-corner code used (just parameterized over isLeft/isTop/startAngle
    // instead of being copy-pasted four times), producing a small wedge
    // flush with the two edges that curves away near the interior corner.
    // Earlier attempts to "fix" this by swapping in a Rectangle corner-radius
    // or a hand-rolled Canvas arc both changed the actual shape for the
    // worse - the bug reports were right and this plain revert is the fix.
    // Used only for the black "screen rounder" accent below - confirmed
    // correct, left untouched.
    component CornerShape: Shape {
        id: shape
        required property real rounding
        // Size of the square window this wedge is being drawn into - the
        // "far corner" reference for whichever axis isLeft/isTop don't pin
        // to 0. This must be THIS shape's own containing box, not a global
        // constant: hardcoding the corner-window size here was exactly the
        // earlier bug (only ever exercised inside one fixed box size, so it
        // silently broke the moment the same wedge math got reused inside a
        // differently-sized box, e.g. the bar/edge-strip fillet).
        required property real boxSize
        required property color fillColor
        required property bool isLeft
        required property bool isTop
        required property int cornerStartAngle

        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: shapePath
            strokeWidth: 0
            fillColor: shape.fillColor

            // The true far corner of the containing box - fixed regardless
            // of this wedge's own radius. Using `rounding` here (instead of
            // the box's actual size) is only correct when rounding ==
            // boxSize, which held for the outer accent but not for a
            // smaller nested one - that's what was dragging the inner
            // corner away from the real corner on every side except
            // top-left (where isLeft and isTop both collapse the
            // expression to 0 regardless).
            startX: shape.isLeft ? 0 : shape.boxSize
            startY: shape.isTop ? 0 : shape.boxSize

            PathAngleArc {
                moveToStart: false
                centerX: shape.isLeft ? shape.rounding : shape.boxSize - shape.rounding
                centerY: shape.isTop ? shape.rounding : shape.boxSize - shape.rounding
                radiusX: shape.rounding
                radiusY: shape.rounding
                startAngle: shape.cornerStartAngle
                sweepAngle: 90
            }

            PathLine { x: shapePath.startX; y: shapePath.startY }
        }
    }

    // The frame's own corner joint: a window into one corner of a virtual,
    // larger rounded rectangle. Clipping a radius x radius box around that
    // corner shows a constant-width curve (real Rectangle border rendering,
    // not hand-rolled arc math) that continues in a dead straight line into
    // the edge strips right at the clip boundary - so the border reads as
    // one continuous uniform-width shape, not a separate blob glued on.
    component FrameCornerPiece: Item {
        id: piece
        required property bool isLeft
        required property bool isTop

        width: frameCornerRadius
        height: frameCornerRadius
        clip: true

        x: isLeft ? 0 : parent.width - frameCornerRadius
        y: isTop ? 0 : parent.height - frameCornerRadius

        Rectangle {
            width: frameCornerRadius * 2
            height: frameCornerRadius * 2
            x: piece.isLeft ? 0 : -frameCornerRadius
            y: piece.isTop ? 0 : -frameCornerRadius
            radius: frameCornerRadius
            color: "transparent"
            border.width: edgeThickness
            border.color: frameColor
        }
    }

    // Softens the seam right under the bar where its bottom edge meets the
    // thin vertical edge strip: without this, the strip starts at a hard
    // right angle at (edgeThickness, barHeight) - the top-left corner of the
    // content area - instead of curving into it like the bottom corners do.
    // This reuses the exact same wedge math as the black screen-rounder
    // corner (CornerShape) - a small quarter-circle sliver filled solid and
    // tucked into that junction - just filled with the frame color and
    // placed at the bar/strip seam instead of the true screen corner.
    component BarFillet: PanelWindow {
        id: fillet
        required property ShellScreen targetScreen
        required property bool isLeft

        screen: targetScreen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        visible: !isFrameHidden(fillet.targetScreen)
        mask: Region {}

        anchors {
            top: true
            left: isLeft
            right: !isLeft
        }
        margins {
            left: isLeft ? edgeThickness : 0
            right: isLeft ? 0 : edgeThickness
            top: barHeight
        }

        implicitWidth: frameCornerRadius
        implicitHeight: frameCornerRadius

        CornerShape {
            // contentCornerRadius, not frameCornerRadius - see its
            // definition above. This is what makes the curve here match the
            // bottom corners' actual curvature instead of a bigger, gentler
            // one.
            rounding: contentCornerRadius
            boxSize: frameCornerRadius
            fillColor: frameColor
            isLeft: fillet.isLeft
            isTop: true
            cornerStartAngle: fillet.isLeft ? 180 : -90
        }
    }

    // One decorative corner badge. Sits on the Overlay layer so it always
    // reads as "on top" of the bar, the dashboard and every app window - an
    // empty mask keeps it from ever intercepting a click despite that.
    component CornerWindow: PanelWindow {
        id: cornerWindow
        required property ShellScreen targetScreen
        required property int corner // 0=TopLeft, 1=TopRight, 2=BottomLeft, 3=BottomRight

        screen: targetScreen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        visible: true
        mask: Region {}

        readonly property bool isTopSide: corner === 0 || corner === 1
        readonly property bool isLeftSide: corner === 0 || corner === 2
        readonly property int cornerStartAngle: [180, -90, 90, 0][corner]

        anchors {
            top: isTopSide
            bottom: !isTopSide
            left: isLeftSide
            right: !isLeftSide
        }
        // Flush with the true screen corner - no bar offset. This is the
        // "screen rounding" mask, and it's meant to sit above everything
        // that lives in that corner, bar included, so it has to actually
        // occupy the real corner rather than one inset below the bar.
        implicitWidth: frameRounding
        implicitHeight: frameRounding

        // Only the bottom corners get the frame's own rounded joint here -
        // the top corners' frame run is the bar's own bottom edge
        // (Bar.qml), which is already flush with the bar and needs no
        // separate piece or bar-height offset glued on below it.
        FrameCornerPiece {
            visible: !cornerWindow.isTopSide && !isFrameHidden(cornerWindow.targetScreen)
            isLeft: cornerWindow.isLeftSide
            isTop: cornerWindow.isTopSide
        }

        CornerShape {
            rounding: innerRounding
            boxSize: frameRounding
            fillColor: innerFrameColor
            isLeft: cornerWindow.isLeftSide
            isTop: cornerWindow.isTopSide
            cornerStartAngle: cornerWindow.cornerStartAngle
        }
    }

    // A thin decorative strip along one full screen edge - same
    // always-on-top, fully click-through treatment as the corners. Stops
    // short of the frame's own corner joints on both ends rather than
    // running full-length, so the two never need to agree on stacking order
    // to look continuous - they just tile. There's no "top" strip: the
    // bar's own bottom edge (Bar.qml) already is the frame's top run, flush
    // against it with no separate piece and no seam.
    component EdgeStrip: PanelWindow {
        id: edge
        required property ShellScreen targetScreen
        required property string side // "bottom" | "left" | "right"

        readonly property bool isVertical: side === "left" || side === "right"

        screen: targetScreen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        color: frameColor
        visible: !isFrameHidden(targetScreen)
        mask: Region {}

        anchors {
            top: side !== "bottom"
            bottom: side !== "top"
            left: side !== "right"
            right: side !== "left"
        }

        // Left/right strips run from right below the bar down to the
        // bottom corner joint; the bottom strip runs between the two
        // bottom corner joints. Nothing here is inset for the bar beyond
        // simply starting below it - the frame's rounded corner only
        // exists at the bottom now.
        margins {
            left: isVertical ? 0 : frameCornerRadius
            right: isVertical ? 0 : frameCornerRadius
            top: isVertical ? barHeight : 0
            bottom: isVertical ? frameCornerRadius : 0
        }

        implicitWidth: isVertical ? edgeThickness : 1
        implicitHeight: isVertical ? 1 : edgeThickness
    }

    // Each corner/edge gets its own flat `Variants` over the screen list -
    // matching the simple one-window-per-screen pattern Bar.qml already uses
    // successfully - rather than one Variants nesting a Scope with 8
    // children per screen. That nested form was silently dropping 3 of the
    // 4 corners on every monitor but the first one Quickshell enumerated.
    Variants {
        model: Quickshell.screens
        CornerWindow { required property ShellScreen modelData; targetScreen: modelData; corner: 0 }
    }
    Variants {
        model: Quickshell.screens
        CornerWindow { required property ShellScreen modelData; targetScreen: modelData; corner: 1 }
    }
    Variants {
        model: Quickshell.screens
        CornerWindow { required property ShellScreen modelData; targetScreen: modelData; corner: 2 }
    }
    Variants {
        model: Quickshell.screens
        CornerWindow { required property ShellScreen modelData; targetScreen: modelData; corner: 3 }
    }

    Variants {
        model: Quickshell.screens
        EdgeStrip { required property ShellScreen modelData; targetScreen: modelData; side: "bottom" }
    }
    Variants {
        model: Quickshell.screens
        EdgeStrip { required property ShellScreen modelData; targetScreen: modelData; side: "left" }
    }
    Variants {
        model: Quickshell.screens
        EdgeStrip { required property ShellScreen modelData; targetScreen: modelData; side: "right" }
    }

    Variants {
        model: Quickshell.screens
        BarFillet { required property ShellScreen modelData; targetScreen: modelData; isLeft: true }
    }
    Variants {
        model: Quickshell.screens
        BarFillet { required property ShellScreen modelData; targetScreen: modelData; isLeft: false }
    }
}
