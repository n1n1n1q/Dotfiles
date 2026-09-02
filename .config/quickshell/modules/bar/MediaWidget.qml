import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets
import qs.modules.popout

// Bar "now playing": an end-4-style filled circular gauge (wedge = track
// position) with a music-note glyph knocked through the centre, plus the current
// track as plain text. Always visible - "Nothing playing" when no MPRIS player
// is active, and inert until one shows up (there is no card to pop out).
// HoverPill gives it its own hover wash inside the left cluster.
HoverPill {
    id: root

    property string screenName: ""
    spacing: Theme.spacing.tiny

    readonly property bool hasPlayer: Media.activePlayer !== null

    // Gauge keeps play/pause (its own MouseArea); clicking the label / dead
    // space opens the media popout - but only while there is something to show.
    clickable: hasPlayer
    onClicked: {
        const p = mapToItem(null, width / 2, 0);
        PopoutController.toggle("media", p.x, width, screenName);
    }

    CircularWidget {
        id: widget

        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: Theme.widget.circularSize
        Layout.preferredHeight: Theme.widget.circularSize

        size: Theme.widget.circularSize
        value: Media.progress
        progressColor: Theme.colors.accent

        iconText: "󰝚" // nf-md-music (the wedge shows track position; click toggles play)

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            enabled: root.hasPlayer
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Media.togglePlayPause()
        }
    }

    Text {
        // Fixed width so the whole widget never changes size as tracks
        // change - the bar layout around it stays put.
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: BarConfig.widgetSetting("media", "width")
        // Centre the label whenever it fits; only left-align once it must elide.
        horizontalAlignment: implicitWidth <= width ? Text.AlignHCenter : Text.AlignLeft
        elide: Text.ElideRight
        font.family: Theme.font.main
        font.pointSize: Theme.bar.fontSizeSmall
        font.weight: root.hasPlayer ? Theme.font.mediumWeight : Theme.font.regular
        color: root.hasPlayer ? Theme.colors.textPrimary : Theme.colors.textTertiary
        text: {
            if (!root.hasPlayer)
                return "Nothing playing";
            if (Media.artist.length > 0)
                return Media.artist + "  —  " + Media.title;
            return Media.title;
        }
    }
}
