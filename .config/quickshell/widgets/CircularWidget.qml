import QtQuick
import qs.config

/**
 * Circular gauge with two switchable looks (Theme.widget.circularStyle, or the
 * per-instance `style` override):
 *
 *  - "filled"  end-4 style: a faint full disc of `progressColor` with a solid
 *              pie-wedge sweeping from 12 o'clock as `value` (0..1) climbs; the
 *              centre glyph is knocked through in `Theme.colors.bg`.
 *  - "ring"    the previous style: a thin full track ring plus a rounded-cap
 *              progress arc; the centre glyph is drawn solid in `iconColor`.
 *
 * `backgroundColor` / `borderColor` / `borderWidth` / `arcThickness` are kept as
 * no-op properties so old call sites don't break.
 */
Item {
    id: root

    property string style: Theme.widget.circularStyle
    readonly property bool filled: style !== "ring"

    property real value: 0.0
    property color progressColor: Theme.colors.accent
    property color trackColor: Qt.rgba(progressColor.r, progressColor.g, progressColor.b, filled ? 0.25 : 0.22)
    property int size: Theme.bar.iconSize
    property string iconText: ""
    // Every glyph `iconText` can be handed. The centre is sized from the set
    // so it holds still when the state changes: a Nerd-Font glyph is drawn
    // wider than the cell it measures, so a plain Text shifts as it swaps.
    // See GlyphIcon.
    property var iconStates: []
    property color iconColor: filled ? Theme.colors.bg : Theme.colors.textPrimary
    property int iconSize: Math.round(size * (filled ? 0.44 : 0.4))
    // How far the drawing sits inside the widget box (leaves a little air).
    property real fillInset: Math.max(2, size * 0.12)
    property real ringWidth: Theme.widget.circularRingWidth
    property real animationDuration: Theme.animation.slow

    // Kept for source compatibility with older call sites - unused.
    property color backgroundColor
    property color borderColor
    property int borderWidth: 0
    property real arcThickness: 3

    // Optional pulse ring for special states (battery charging).
    property alias overlayVisible: overlay.visible
    property alias overlayOpacity: overlay.opacity
    property color overlayColor: Theme.colors.warning

    implicitWidth: size
    implicitHeight: size

    property real animatedValue: Math.max(0, Math.min(1, isFinite(value) ? value : 0))
    Behavior on animatedValue {
        NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        property real v: root.animatedValue
        property color pc: root.progressColor
        property color tc: root.trackColor
        property real fi: root.fillInset
        property bool fl: root.filled
        property real rw: root.ringWidth
        onVChanged: requestPaint()
        onPcChanged: requestPaint()
        onTcChanged: requestPaint()
        onFiChanged: requestPaint()
        onFlChanged: requestPaint()
        onRwChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2
            const cy = height / 2
            const top = -Math.PI / 2

            if (canvas.fl) {
                const r = Math.min(width, height) / 2 - canvas.fi
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                ctx.fillStyle = canvas.tc
                ctx.fill()
                if (canvas.v > 0) {
                    ctx.beginPath()
                    ctx.moveTo(cx, cy)
                    ctx.arc(cx, cy, r, top, top + 2 * Math.PI * canvas.v, false)
                    ctx.closePath()
                    ctx.fillStyle = canvas.pc
                    ctx.fill()
                }
            } else {
                const r = Math.min(width, height) / 2 - canvas.fi - canvas.rw / 2
                ctx.lineWidth = canvas.rw
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                ctx.strokeStyle = canvas.tc
                ctx.stroke()
                if (canvas.v > 0) {
                    ctx.beginPath()
                    ctx.lineCap = "round"
                    ctx.arc(cx, cy, r, top, top + 2 * Math.PI * canvas.v, false)
                    ctx.strokeStyle = canvas.pc
                    ctx.stroke()
                }
            }
        }
    }

    GlyphIcon {
        anchors.centerIn: parent
        text: root.iconText
        glyphs: root.iconStates
        font.family: Theme.font.icon
        font.pointSize: root.iconSize
        font.weight: Font.DemiBold
        color: root.iconColor
        visible: root.iconText !== ""
    }

    Canvas {
        id: overlay
        anchors.fill: parent
        antialiasing: true
        visible: false

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2
            const cy = height / 2
            const r = Math.min(width, height) / 2 - Math.max(1, root.fillInset - 1)
            ctx.lineWidth = 1.5
            ctx.strokeStyle = root.overlayColor
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
            ctx.stroke()
        }
        onVisibleChanged: if (visible) requestPaint()
    }
}
