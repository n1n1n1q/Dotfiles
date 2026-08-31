import QtQuick
import QtQuick.Effects
import qs.config
import qs.services
import qs.widgets

// end-4-style now-playing card: blurred album art behind, with the body itself
// drawn by the shared MediaLayout in whichever of the four layouts Settings >
// Bar has picked. Opened from the bar's media widget label.
Rectangle {
    id: root

    implicitWidth: body.implicitWidth
    implicitHeight: body.implicitHeight
    radius: Theme.popup.radius
    color: Theme.popup.background
    border.width: Theme.popup.borderWidth
    border.color: Theme.popup.border
    clip: true

    // --- blurred art backdrop ------------------------------------------
    Image {
        id: art
        anchors.fill: parent
        source: Media.artUrl
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: true
        visible: false
    }
    // `clip` only clips to the bounding box, so the backdrop squares the card's
    // corners back up unless it is rounded off itself. One MultiEffect can't
    // blur and mask in the same pass - the blur comes out unmasked - so the
    // blurred art is flattened into a layer and the mask applied to that.
    Rectangle {
        id: cardMask
        anchors.fill: parent
        radius: root.radius
        color: "black"
        visible: false
        layer.enabled: true
    }
    Item {
        anchors.fill: parent
        visible: art.status === Image.Ready
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: cardMask
        }

        MultiEffect {
            anchors.fill: parent
            source: art
            blurEnabled: true
            blur: 1
            blurMax: 48
            brightness: -0.25
            saturation: 0.1
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.popup.background
        opacity: art.status === Image.Ready ? 0.55 : 1
    }

    MediaLayout {
        id: body
        anchors.fill: parent
        variant: BarConfig.mediaLayout
    }
}
