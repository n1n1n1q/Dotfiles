import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Bar volume indicator: an end-4-style filled circular gauge whose wedge tracks
// Audio.volume (green, or red when muted), with a fixed music-note glyph knocked
// through the centre. No percent readout, no pill background; same size as the
// other bar circles. Scroll = volume, right-click = mute.
CircularWidget {
    id: root

    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: Theme.widget.circularSize
    Layout.preferredHeight: Theme.widget.circularSize

    size: Theme.widget.circularSize
    value: Audio.volume
    progressColor: Audio.muted ? Theme.colors.error : Theme.colors.success

    iconText: Audio.muted ? "󰝛" : "󰎇" // nf-md-music_off / nf-md-music_note

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Audio.toggleMute()
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                Audio.incrementVolume()
            else
                Audio.decrementVolume()
        }
    }
}
