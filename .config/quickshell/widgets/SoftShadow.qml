import QtQuick
import qs.config

// A soft drop shadow for a rounded surface. Drop it in as the first child of
// the surface (it sits behind at z: -1 by default and fills it):
//
//     Rectangle {
//         radius: Theme.rounding.panel
//         SoftShadow {}
//         ...content...
//     }
//
// It replaces the single hard `-5px` inflated rectangle every floating surface
// used to carry — that read as a dark border, not a shadow. This stacks a few
// translucent layers of shrinking size and rising alpha, painted outermost
// first, so the edge actually falls off. The surface itself paints opaquely on
// top, so only the halo shows.
Item {
    id: root

    property Item target: parent
    // Corner radius of the surface being shadowed. Defaults to the target's own
    // radius (if it has one), else the standard floating-surface radius.
    property int radius: (target && target.radius !== undefined)
        ? target.radius : Theme.rounding.panel
    // How far the outermost layer reaches past the surface edge.
    property int spread: 24
    // Peak opacity, in the layer hugging the surface.
    property real strength: 0.5
    property color tint: "#000000"
    property int layers: 5

    anchors.fill: target
    z: -1

    Repeater {
        model: root.layers

        Rectangle {
            required property int index
            // index 0 = outermost + faintest (drawn first, at the back);
            // last index = hugs the surface + darkest (drawn last, on top).
            readonly property real out: (root.layers - index) / root.layers
            anchors.centerIn: parent
            width: root.width + root.spread * 2 * out
            height: root.height + root.spread * 2 * out
            radius: root.radius + root.spread * out
            color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b,
                           root.strength * (index + 1) / root.layers / root.layers * 1.8)
        }
    }
}
