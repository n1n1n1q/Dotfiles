import QtQuick
import qs.config
import qs.services
import qs.widgets

// Now-playing card for the bar's media popout — the shared MediaLayout body in
// whichever of the four layouts Settings > Bar has picked, sitting on the plain
// popup background. (There used to be a blurred album-art backdrop here; it
// read as muddy behind the controls, so it's gone — the cover art still shows
// in MediaLayout itself.)
Rectangle {
    id: root

    implicitWidth: body.implicitWidth
    implicitHeight: body.implicitHeight
    radius: Theme.popup.radius
    color: Theme.popup.background
    border.width: Theme.popup.borderWidth
    border.color: Theme.popup.border
    clip: true

    MediaLayout {
        id: body
        anchors.fill: parent
        variant: BarConfig.mediaLayout
    }
}
