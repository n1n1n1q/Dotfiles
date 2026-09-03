import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config

// Screen-edge decoration: a thin frame border on the three (or four) edges the
// bar doesn't occupy, its rounded corner joints, and the black "screen rounder"
// accents. All three are independently toggleable via BarConfig.style
// (`frame` / `rounded` / `blackCorners`) and the whole thing follows the bar to
// whichever edge it's docked on.
Scope {
    readonly property int frameRounding: 60   // fixed corner-window box size
    readonly property int innerRounding: 34   // black "screen rounding" radius
    readonly property int barHeight: Theme.bar.height
    readonly property color frameColor: Theme.frame.color
    readonly property color innerFrameColor: Theme.frame.innerColor
    readonly property int edgeThickness: Theme.frame.thickness

    // --- live style ----------------------------------------------------
    readonly property string barEdge: BarConfig.edge          // top|bottom|left|right
    readonly property bool barFloating: BarConfig.floating
    readonly property bool frameOn: BarConfig.frameEnabled
    // The black screen-rounder accents — independent of everything else, works
    // in floating/pill mode too.
    readonly property bool cornersOn: BarConfig.blackCorners
    readonly property bool roundedOn: BarConfig.frameRounded
    // Corner radius is a geometry constant; whether a given corner is rounded
    // is decided per-corner below (rounded toggle, black accent, or neither).
    readonly property int frameCornerRadius: Theme.frame.cornerRadius
    // Content-side curvature of a border.width-thick corner ring.
    readonly property int contentCornerRadius: Math.max(0, frameCornerRadius - edgeThickness)
    // The fillet tucks past the border strip when there is one, flush to the
    // screen edge when there isn't (no phantom margin without a frame).
    readonly property int filletEdgeInset: frameOn ? edgeThickness : 0

    // corner: 0=TopLeft 1=TopRight 2=BottomLeft 3=BottomRight
    function edgeTouchesCorner(edge, corner) {
        if (edge === "top") return corner === 0 || corner === 1;
        if (edge === "bottom") return corner === 2 || corner === 3;
        if (edge === "left") return corner === 0 || corner === 2;
        if (edge === "right") return corner === 1 || corner === 3;
        return false;
    }
    // A docked bar sits on two corners — they never get a frame joint.
    function cornerIsBarSide(corner) {
        return !barFloating && edgeTouchesCorner(barEdge, corner);
    }
    // Those two corners get a bar-coloured seam-softening fillet — driven by
    // the `rounded` toggle only (black-corners-but-not-rounded → square bar
    // seam, rounded joint on the other corners).
    function cornerHasFillet(corner) {
        return roundedOn && cornerIsBarSide(corner);
    }
    // Every other corner gets the rounded frame-border joint when the frame is
    // on and EITHER `rounded` or the black accent wants a curve there (a square
    // border corner inside a rounded black corner looks broken).
    function cornerHasJoint(corner) {
        return frameOn && !cornerIsBarSide(corner) && (roundedOn || cornersOn);
    }
    // How far the frame yields on a given side — barHeight where the bar docks.
    function sideInset(side) {
        return (!barFloating && side === barEdge) ? barHeight : 0;
    }
    // Is there a border strip on this side at all?
    function sideHasStrip(side) {
        return frameOn && !(!barFloating && side === barEdge);
    }
    // Strips stop short of a corner for its joint AND for the black accent
    // (cross-window stacking is unreliable — better to leave the room than
    // hope the accent draws on top).
    function endMargin(endSide, corner) {
        return Math.max(
            sideInset(endSide),
            cornerHasJoint(corner) ? frameCornerRadius : 0,
            cornersOn ? innerRounding : 0);
    }

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

    // Hand-rolled wedge, used only for the black screen-rounder accent and the
    // bar/strip fillet. Left untouched — see git history for why every "fix"
    // here was a regression.
    component CornerShape: Shape {
        id: shape
        required property real rounding
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

    // The frame's own corner joint: a constant-width curve clipped from one
    // corner of a virtual 2r rounded rectangle.
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

    // Softens the seam where a docked bar's edge meets a perpendicular run.
    // One per corner the bar touches; a bar-coloured quarter-circle tucked into
    // that inside corner. Works for every edge (and even with the frame off —
    // it just rounds the bar into the screen corner).
    component BarFillet: PanelWindow {
        id: fillet
        required property ShellScreen targetScreen
        required property int corner   // 0..3

        readonly property bool cIsLeft: corner === 0 || corner === 2
        readonly property bool cIsTop: corner === 0 || corner === 1
        readonly property bool barHoriz: barEdge === "top" || barEdge === "bottom"

        screen: targetScreen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        visible: cornerHasFillet(fillet.corner) && !isFrameHidden(fillet.targetScreen)
        mask: Region {}

        anchors {
            top: fillet.cIsTop
            bottom: !fillet.cIsTop
            left: fillet.cIsLeft
            right: !fillet.cIsLeft
        }
        margins {
            left: fillet.cIsLeft ? (fillet.barHoriz ? filletEdgeInset : barHeight) : 0
            right: !fillet.cIsLeft ? (fillet.barHoriz ? filletEdgeInset : barHeight) : 0
            top: fillet.cIsTop ? (fillet.barHoriz ? barHeight : filletEdgeInset) : 0
            bottom: !fillet.cIsTop ? (fillet.barHoriz ? barHeight : filletEdgeInset) : 0
        }

        implicitWidth: frameCornerRadius
        implicitHeight: frameCornerRadius

        CornerShape {
            // With a border strip the fillet matches the content-side curve;
            // bare (no frame) it matches the black accent's screen rounding.
            rounding: frameOn ? contentCornerRadius : frameCornerRadius
            boxSize: frameCornerRadius
            fillColor: frameColor
            isLeft: fillet.cIsLeft
            isTop: fillet.cIsTop
            cornerStartAngle: [180, -90, 90, 0][fillet.corner]
        }
    }

    // One decorative corner: the frame's rounded joint (when that corner has
    // one) plus the black screen-rounder accent (independent toggle).
    component CornerWindow: PanelWindow {
        id: cornerWindow
        required property ShellScreen targetScreen
        required property int corner

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
        implicitWidth: frameRounding
        implicitHeight: frameRounding

        // Behind the border joint: fill the outside-of-the-curve sliver with
        // the frame colour so a frame with no black accent still reads as a
        // solid rounded rectangle (no see-through corner). Covered by the
        // black accent when that's on.
        CornerShape {
            visible: frameOn && cornerHasJoint(cornerWindow.corner)
                && !isFrameHidden(cornerWindow.targetScreen)
            rounding: innerRounding
            boxSize: frameRounding
            fillColor: frameColor
            isLeft: cornerWindow.isLeftSide
            isTop: cornerWindow.isTopSide
            cornerStartAngle: cornerWindow.cornerStartAngle
        }

        FrameCornerPiece {
            visible: cornerHasJoint(cornerWindow.corner)
                && !isFrameHidden(cornerWindow.targetScreen)
            isLeft: cornerWindow.isLeftSide
            isTop: cornerWindow.isTopSide
        }

        CornerShape {
            visible: cornersOn
            rounding: innerRounding
            boxSize: frameRounding
            fillColor: innerFrameColor
            isLeft: cornerWindow.isLeftSide
            isTop: cornerWindow.isTopSide
            cornerStartAngle: cornerWindow.cornerStartAngle
        }
    }

    // A thin border strip along one full screen edge. Yields barHeight where
    // the bar docks and frameCornerRadius at each rounded corner joint.
    component EdgeStrip: PanelWindow {
        id: edge
        required property ShellScreen targetScreen
        required property string side // "top" | "bottom" | "left" | "right"

        readonly property bool isVertical: side === "left" || side === "right"
        // perpendicular corners at this strip's two ends
        readonly property int endCornerA: side === "top" ? 0 : side === "bottom" ? 2
            : side === "left" ? 0 : 1
        readonly property int endCornerB: side === "top" ? 1 : side === "bottom" ? 3
            : side === "left" ? 2 : 3
        readonly property string endSideA: isVertical ? "top" : "left"
        readonly property string endSideB: isVertical ? "bottom" : "right"

        screen: targetScreen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        color: frameColor
        visible: sideHasStrip(edge.side) && !isFrameHidden(targetScreen)
        mask: Region {}

        anchors {
            top: side !== "bottom"
            bottom: side !== "top"
            left: side !== "right"
            right: side !== "left"
        }
        margins {
            top: isVertical ? endMargin(edge.endSideA, edge.endCornerA) : 0
            bottom: isVertical ? endMargin(edge.endSideB, edge.endCornerB) : 0
            left: isVertical ? 0 : endMargin(edge.endSideA, edge.endCornerA)
            right: isVertical ? 0 : endMargin(edge.endSideB, edge.endCornerB)
        }

        implicitWidth: isVertical ? edgeThickness : 1
        implicitHeight: isVertical ? 1 : edgeThickness
    }

    // A soft shadow cast inward onto the content, when BarConfig.style.shadow
    // is on. One window per screen owns the whole shape: the bar, the frame
    // border and the rounded corner joint are treated as one object, and the
    // shadow is a soft band hugging the *inside* of the content well's edge —
    // corners included, since the well is a single rounded rect. It never
    // reaches the frame decoration itself (the band is clipped to the well),
    // so nothing tints the corner. Purely decorative: always-mapped,
    // click-through, ignored by the exclusive zone.
    component ContentShadow: PanelWindow {
        id: cs
        required property ShellScreen targetScreen

        readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.4)
        readonly property int depth: 26

        // Content-well insets: the bar's height on its docked edge, the border
        // thickness on every framed edge, nothing on a bare edge.
        function wellInset(side) {
            if (barFloating) return 0;
            if (side === barEdge) return barHeight;
            return frameOn ? edgeThickness : 0;
        }
        readonly property int insetT: wellInset("top")
        readonly property int insetB: wellInset("bottom")
        readonly property int insetL: wellInset("left")
        readonly property int insetR: wellInset("right")
        readonly property int wellRadius: frameOn && roundedOn ? contentCornerRadius : 0

        readonly property int layers: 16

        screen: targetScreen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:content-shadow"
        color: "transparent"
        mask: Region {}
        visible: BarConfig.shadowEnabled && !barFloating
            && (frameOn || insetT || insetB || insetL || insetR)
            && !isFrameHidden(targetScreen)
        anchors { top: true; bottom: true; left: true; right: true }

        // A stack of hollow rounded-rect frames, inset progressively into the
        // content well with a decaying alpha — the same idea as widgets/
        // SoftShadow, turned inward. Every frame sits inside the well, so the
        // shadow is only ever on the content, follows the rounded corner, and
        // never touches the frame decoration.
        Repeater {
            model: cs.layers

            Rectangle {
                required property int index
                readonly property real t: index / (cs.layers - 1)   // 0 → 1 inward
                readonly property real off: t * cs.depth

                x: cs.insetL + off
                y: cs.insetT + off
                width: cs.width - cs.insetL - cs.insetR - off * 2
                height: cs.height - cs.insetT - cs.insetB - off * 2
                radius: Math.max(0, cs.wellRadius - off)
                antialiasing: true
                color: "transparent"
                // Each stroke is ~3× the step between layers, so every point is
                // painted by several overlapping strokes — that overlap is what
                // smooths the falloff into a gradient instead of visible rings.
                border.width: cs.depth / cs.layers * 3.2
                border.color: Qt.rgba(cs.shadowColor.r, cs.shadowColor.g, cs.shadowColor.b,
                                      cs.shadowColor.a * (1 - t) / cs.layers * 1.6)
            }
        }
    }

    Variants { model: Quickshell.screens
        ContentShadow { required property ShellScreen modelData; targetScreen: modelData } }

    Variants { model: Quickshell.screens
        CornerWindow { required property ShellScreen modelData; targetScreen: modelData; corner: 0 } }
    Variants { model: Quickshell.screens
        CornerWindow { required property ShellScreen modelData; targetScreen: modelData; corner: 1 } }
    Variants { model: Quickshell.screens
        CornerWindow { required property ShellScreen modelData; targetScreen: modelData; corner: 2 } }
    Variants { model: Quickshell.screens
        CornerWindow { required property ShellScreen modelData; targetScreen: modelData; corner: 3 } }

    Variants { model: Quickshell.screens
        EdgeStrip { required property ShellScreen modelData; targetScreen: modelData; side: "top" } }
    Variants { model: Quickshell.screens
        EdgeStrip { required property ShellScreen modelData; targetScreen: modelData; side: "bottom" } }
    Variants { model: Quickshell.screens
        EdgeStrip { required property ShellScreen modelData; targetScreen: modelData; side: "left" } }
    Variants { model: Quickshell.screens
        EdgeStrip { required property ShellScreen modelData; targetScreen: modelData; side: "right" } }

    Variants { model: Quickshell.screens
        BarFillet { required property ShellScreen modelData; targetScreen: modelData; corner: 0 } }
    Variants { model: Quickshell.screens
        BarFillet { required property ShellScreen modelData; targetScreen: modelData; corner: 1 } }
    Variants { model: Quickshell.screens
        BarFillet { required property ShellScreen modelData; targetScreen: modelData; corner: 2 } }
    Variants { model: Quickshell.screens
        BarFillet { required property ShellScreen modelData; targetScreen: modelData; corner: 3 } }
}
