import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.config

// Screen-edge decoration — a thin frame border on the edges the bar doesn't
// occupy, its rounded corner joints, and the black "screen rounder" accents,
// all toggleable via BarConfig.style (`frame` / `rounded` / `blackCorners`).
//
// Once its own consolidated overlay window; now just a fill-parent Item hosted
// by the shared Drawers window alongside the bar / OSD / notifications, so the
// whole screen edge is a single Wayland surface + GL context.
Item {
    id: root
    anchors.fill: parent

    // The Drawers host passes this — true while a fullscreen window covers this
    // output, hiding the border/shadow (but not the black corner accents).
    property bool screenHidden: false

    readonly property int frameRounding: 60   // fixed corner box size
    readonly property int innerRounding: 34   // black "screen rounding" radius
    readonly property int barHeight: Theme.bar.height
    readonly property color frameColor: Theme.frame.color
    readonly property color innerFrameColor: Theme.frame.innerColor
    readonly property int edgeThickness: Theme.frame.thickness

    // --- live style ----------------------------------------------------
    readonly property string barEdge: BarConfig.edge          // top|bottom|left|right
    readonly property bool barFloating: BarConfig.floating
    readonly property bool frameOn: BarConfig.frameEnabled
    readonly property bool cornersOn: BarConfig.blackCorners
    readonly property bool roundedOn: BarConfig.frameRounded
    readonly property int frameCornerRadius: Theme.frame.cornerRadius
    readonly property int contentCornerRadius: Math.max(0, frameCornerRadius - edgeThickness)
    readonly property int filletEdgeInset: frameOn ? edgeThickness : 0

    // corner: 0=TopLeft 1=TopRight 2=BottomLeft 3=BottomRight
    function edgeTouchesCorner(edge, corner) {
        if (edge === "top") return corner === 0 || corner === 1;
        if (edge === "bottom") return corner === 2 || corner === 3;
        if (edge === "left") return corner === 0 || corner === 2;
        if (edge === "right") return corner === 1 || corner === 3;
        return false;
    }
    function cornerIsBarSide(corner) {
        return !barFloating && edgeTouchesCorner(barEdge, corner);
    }
    function cornerHasFillet(corner) {
        return roundedOn && cornerIsBarSide(corner);
    }
    function cornerHasJoint(corner) {
        return frameOn && !cornerIsBarSide(corner) && (roundedOn || cornersOn);
    }
    function sideInset(side) {
        return (!barFloating && side === barEdge) ? barHeight : 0;
    }
    function sideHasStrip(side) {
        return frameOn && !(!barFloating && side === barEdge);
    }
    function endMargin(endSide, corner) {
        return Math.max(
            sideInset(endSide),
            cornerHasJoint(corner) ? frameCornerRadius : 0,
            cornersOn ? innerRounding : 0);
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

    // One decorative corner: the frame's rounded joint (when that corner has
    // one) plus the black screen-rounder accent (independent toggle).
    component CornerPiece: Item {
        id: cp
        required property int corner
        property bool cHidden: false

        readonly property bool isTopSide: corner === 0 || corner === 1
        readonly property bool isLeftSide: corner === 0 || corner === 2
        readonly property int cornerStartAngle: [180, -90, 90, 0][corner]

        width: frameRounding
        height: frameRounding

        CornerShape {
            visible: frameOn && cornerHasJoint(cp.corner) && !cp.cHidden
            rounding: innerRounding
            boxSize: frameRounding
            fillColor: frameColor
            isLeft: cp.isLeftSide
            isTop: cp.isTopSide
            cornerStartAngle: cp.cornerStartAngle
        }

        FrameCornerPiece {
            visible: cornerHasJoint(cp.corner) && !cp.cHidden
            isLeft: cp.isLeftSide
            isTop: cp.isTopSide
        }

        CornerShape {
            visible: cornersOn
            rounding: innerRounding
            boxSize: frameRounding
            fillColor: innerFrameColor
            isLeft: cp.isLeftSide
            isTop: cp.isTopSide
            cornerStartAngle: cp.cornerStartAngle
        }
    }

    // A thin border strip along one full screen edge. Anchors itself to its own
    // edge from `side`; yields barHeight where the bar docks and
    // frameCornerRadius at each rounded corner joint.
    component EdgeStripPiece: Item {
        id: edge
        required property string side // "top" | "bottom" | "left" | "right"
        property bool cHidden: false

        readonly property bool isVertical: side === "left" || side === "right"
        readonly property int endCornerA: side === "top" ? 0 : side === "bottom" ? 2
            : side === "left" ? 0 : 1
        readonly property int endCornerB: side === "top" ? 1 : side === "bottom" ? 3
            : side === "left" ? 2 : 3
        readonly property string endSideA: isVertical ? "top" : "left"
        readonly property string endSideB: isVertical ? "bottom" : "right"

        anchors.top: side !== "bottom" ? parent.top : undefined
        anchors.bottom: side !== "top" ? parent.bottom : undefined
        anchors.left: side !== "right" ? parent.left : undefined
        anchors.right: side !== "left" ? parent.right : undefined
        anchors.topMargin: isVertical ? endMargin(endSideA, endCornerA) : 0
        anchors.bottomMargin: isVertical ? endMargin(endSideB, endCornerB) : 0
        anchors.leftMargin: !isVertical ? endMargin(endSideA, endCornerA) : 0
        anchors.rightMargin: !isVertical ? endMargin(endSideB, endCornerB) : 0
        width: isVertical ? edgeThickness : undefined
        height: isVertical ? undefined : edgeThickness

        visible: sideHasStrip(edge.side) && !edge.cHidden

        Rectangle { anchors.fill: parent; color: frameColor }
    }

    // Softens the seam where a docked bar's edge meets a perpendicular run.
    component BarFilletPiece: Item {
        id: fillet
        required property int corner   // 0..3
        property bool cHidden: false

        readonly property bool cIsLeft: corner === 0 || corner === 2
        readonly property bool cIsTop: corner === 0 || corner === 1
        readonly property bool barHoriz: barEdge === "top" || barEdge === "bottom"

        width: frameCornerRadius
        height: frameCornerRadius

        anchors.top: cIsTop ? parent.top : undefined
        anchors.bottom: !cIsTop ? parent.bottom : undefined
        anchors.left: cIsLeft ? parent.left : undefined
        anchors.right: !cIsLeft ? parent.right : undefined
        anchors.leftMargin: cIsLeft ? (barHoriz ? filletEdgeInset : barHeight) : 0
        anchors.rightMargin: !cIsLeft ? (barHoriz ? filletEdgeInset : barHeight) : 0
        anchors.topMargin: cIsTop ? (barHoriz ? barHeight : filletEdgeInset) : 0
        anchors.bottomMargin: !cIsTop ? (barHoriz ? barHeight : filletEdgeInset) : 0

        visible: cornerHasFillet(fillet.corner) && !fillet.cHidden

        CornerShape {
            rounding: frameOn ? contentCornerRadius : frameCornerRadius
            boxSize: frameCornerRadius
            fillColor: frameColor
            isLeft: fillet.cIsLeft
            isTop: fillet.cIsTop
            cornerStartAngle: [180, -90, 90, 0][fillet.corner]
        }
    }

    // A soft shadow cast inward onto the content well's edge, when
    // BarConfig.style.shadow is on.
    component ContentShadowContent: Item {
        id: cs
        property bool cHidden: false

        anchors.fill: parent

        readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.4)
        readonly property int depth: 26

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

        visible: BarConfig.shadowEnabled && !barFloating
            && (frameOn || insetT || insetB || insetL || insetR)
            && !cs.cHidden

        Repeater {
            model: cs.layers

            Rectangle {
                required property int index
                readonly property real t: index / (cs.layers - 1)
                readonly property real off: t * cs.depth

                x: cs.insetL + off
                y: cs.insetT + off
                width: cs.width - cs.insetL - cs.insetR - off * 2
                height: cs.height - cs.insetT - cs.insetB - off * 2
                radius: Math.max(0, cs.wellRadius - off)
                antialiasing: true
                color: "transparent"
                border.width: cs.depth / cs.layers * 3.2
                border.color: Qt.rgba(cs.shadowColor.r, cs.shadowColor.g, cs.shadowColor.b,
                                      cs.shadowColor.a * (1 - t) / cs.layers * 1.6)
            }
        }
    }

    // Painted back-to-front: shadow, edge strips, bar fillets, then the corners
    // on top — the black screen-rounder accent must sit above the frame joint.
    ContentShadowContent { cHidden: root.screenHidden }

    EdgeStripPiece { side: "top";    cHidden: root.screenHidden }
    EdgeStripPiece { side: "bottom"; cHidden: root.screenHidden }
    EdgeStripPiece { side: "left";   cHidden: root.screenHidden }
    EdgeStripPiece { side: "right";  cHidden: root.screenHidden }

    BarFilletPiece { corner: 0; cHidden: root.screenHidden }
    BarFilletPiece { corner: 1; cHidden: root.screenHidden }
    BarFilletPiece { corner: 2; cHidden: root.screenHidden }
    BarFilletPiece { corner: 3; cHidden: root.screenHidden }

    CornerPiece { corner: 0; cHidden: root.screenHidden
        anchors.top: parent.top; anchors.left: parent.left }
    CornerPiece { corner: 1; cHidden: root.screenHidden
        anchors.top: parent.top; anchors.right: parent.right }
    CornerPiece { corner: 2; cHidden: root.screenHidden
        anchors.bottom: parent.bottom; anchors.left: parent.left }
    CornerPiece { corner: 3; cHidden: root.screenHidden
        anchors.bottom: parent.bottom; anchors.right: parent.right }
}
