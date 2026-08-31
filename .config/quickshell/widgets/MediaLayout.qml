import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import qs.config
import qs.services

// The now-playing body shared by the bar's media popout and the desktop media
// widget, in the four layouts offered in Settings:
//
//   regular         record          regularVertical  recordVertical
//   +-----------+   +-----------+   +---------+      +---------+
//   | [] title  |   | () title  |   |   []    |      |   ()    |
//   |    --o--  |   |    --o--  |   |  title  |      |  title  |
//   |    < > >  |   |    < > >  |   |  --o--  |      |  --o--  |
//   +-----------+   +-----------+   |  < > >  |      |  < > >  |
//                                   +---------+      +---------+
//
// The "record" pair swaps the cover thumbnail for a vinyl disc that spins
// while the track plays. Metrics all come off `sc` (a scale factor) and
// `compact` (the tighter desktop-widget sizing); the host draws its own
// background behind this - it is content only.
Item {
    id: root

    // regular | record | regularVertical | recordVertical
    property string variant: "regular"
    property real sc: 1.0
    property bool compact: false
    // The "switch player" button. Only ever shown with more than one player.
    property bool showCycle: true

    readonly property bool vertical: variant === "regularVertical" || variant === "recordVertical"
    readonly property bool disc: variant === "record" || variant === "recordVertical"
    readonly property bool has: Media.activePlayer !== null
    readonly property bool hasArt: artSource.status === Image.Ready

    readonly property int pad: Math.round((compact ? 12 : Theme.popup.padding) * sc)
    readonly property int gap: Math.round((compact ? 10 : Theme.spacing.medium) * sc)
    readonly property int artSize: Math.round(
        (vertical ? (compact ? 112 : 150) : (compact ? 62 : 104)) * sc)

    implicitWidth: Math.round((vertical ? (compact ? 190 : 232) : (compact ? 300 : 344)) * sc)
    implicitHeight: grid.implicitHeight + pad * 2

    // Quickshell hands MPRIS times over in seconds, not the microseconds the
    // bus carries.
    function fmt(secs) {
        if (!secs || secs <= 0) return "0:00";
        const s = Math.floor(secs);
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // --- transport button -------------------------------------------------
    // Inline components can't see the file's ids, so every metric is a property.
    component TBtn: Rectangle {
        id: tb
        property string glyph: ""
        property int size: 30
        property int glyphSize: 11
        property bool primary: false
        property bool can: true
        signal triggered()

        implicitWidth: size
        implicitHeight: size
        radius: height / 2
        color: primary ? Theme.colors.accent
            : (tbMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent")
        opacity: can ? 1 : 0.35

        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

        Text {
            anchors.centerIn: parent
            text: tb.glyph
            font.family: Theme.font.icon
            font.pointSize: tb.glyphSize
            color: tb.primary ? Theme.colors.bg : Theme.colors.textPrimary
        }
        MouseArea {
            id: tbMouse
            anchors.fill: parent
            enabled: tb.can
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tb.triggered()
        }
    }

    // A single grid does both orientations: two columns side by side, or one
    // column with the art stacked on top.
    GridLayout {
        id: grid
        anchors.fill: parent
        anchors.margins: root.pad
        columns: root.vertical ? 1 : 2
        columnSpacing: root.gap
        rowSpacing: root.gap

        // --- cover / vinyl ------------------------------------------------
        Item {
            id: art
            Layout.preferredWidth: root.artSize
            Layout.preferredHeight: root.artSize
            Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter

            // Everything in here turns together, so the label and the grooves
            // ride along with the sleeve art.
            Item {
                id: stage
                anchors.fill: parent
                property real spin: 0
                rotation: root.disc ? spin : 0

                // Held at the last angle while paused rather than restarted,
                // so play/pause doesn't snap the record back to the top.
                NumberAnimation on spin {
                    id: spinAnim
                    running: root.disc && root.visible
                    paused: spinAnim.running && !Media.isPlaying
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 9000
                }

                // plate behind the art: the empty state, and the disc's edge
                Rectangle {
                    anchors.fill: parent
                    radius: root.disc ? width / 2 : Theme.rounding.medium
                    color: root.disc ? Theme.palette.crust : Theme.colors.surfaceVariant
                }

                // One decode of the cover for both the square and the disc
                // treatment; the MultiEffect masks it to whichever shape the
                // layout asks for.
                Image {
                    id: artSource
                    anchors.fill: parent
                    source: Media.artUrl
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    visible: false
                }

                Rectangle {
                    id: mask
                    anchors.fill: parent
                    radius: root.disc ? width / 2 : Theme.rounding.medium
                    color: "black"
                    visible: false
                    layer.enabled: true
                }
                MultiEffect {
                    anchors.fill: parent
                    source: artSource
                    visible: root.hasArt
                    maskEnabled: true
                    maskSource: mask
                }

                Text {
                    anchors.centerIn: parent
                    visible: !root.hasArt
                    // keeps the placeholder upright while the record turns
                    rotation: -stage.rotation
                    text: "󰝚"
                    font.family: Theme.font.icon
                    font.pointSize: Math.round(root.artSize * 0.22)
                    color: Theme.colors.textTertiary
                }

                // grooves + centre label, drawn only on the record
                Repeater {
                    model: root.disc ? [0.86, 0.71, 0.56] : []
                    delegate: Rectangle {
                        required property real modelData
                        anchors.centerIn: parent
                        width: parent.width * modelData
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.22)
                    }
                }
                Rectangle {
                    visible: root.disc && root.hasArt
                    anchors.centerIn: parent
                    width: parent.width * 0.34
                    height: width
                    radius: width / 2
                    color: Theme.colors.accent
                }
                Rectangle {
                    visible: root.disc
                    anchors.centerIn: parent
                    width: Math.max(4, parent.width * 0.1)
                    height: width
                    radius: width / 2
                    color: Theme.colors.background
                }
            }
        }

        // --- title / seek / transport -------------------------------------
        ColumnLayout {
            id: info
            Layout.fillWidth: true
            Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignVCenter
            spacing: Math.round(2 * root.sc)

            Text {
                Layout.fillWidth: true
                horizontalAlignment: root.vertical ? Text.AlignHCenter : Text.AlignLeft
                text: root.has ? Media.title : "Nothing playing"
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Math.round(Theme.font.large * root.sc)
                font.weight: Theme.font.semiBold
                color: Theme.colors.textPrimary
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: root.vertical ? Text.AlignHCenter : Text.AlignLeft
                visible: root.has && text.length > 0
                text: root.compact
                    ? Media.artist
                    : [Media.artist, Media.album].filter(s => s && s.length > 0).join("  ·  ")
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Math.round(Theme.font.normal * root.sc)
                color: Theme.colors.textSecondary
            }

            // Seek bar spans the full text column - the elapsed / total times
            // sit under its ends rather than eating into its width.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Math.round(root.gap * 0.5)
                spacing: 0
                visible: root.has && Media.length > 0

                Slider {
                    id: seek
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(16 * root.sc)
                    padding: 0
                    enabled: Media.hasProgress
                    from: 0
                    to: 1
                    value: Media.length > 0 ? Media.position / Media.length : 0
                    onPressedChanged: {
                        if (!pressed)
                            Media.seek(value * Media.length);
                    }

                    background: Rectangle {
                        x: seek.leftPadding
                        y: seek.topPadding + seek.availableHeight / 2 - height / 2
                        width: seek.availableWidth
                        height: Math.max(3, Math.round(4 * root.sc))
                        radius: height / 2
                        color: Theme.colors.borderSubtle
                        Rectangle {
                            width: seek.visualPosition * parent.width
                            height: parent.height
                            radius: parent.radius
                            color: Theme.colors.accent
                        }
                    }
                    handle: Rectangle {
                        x: seek.leftPadding + seek.visualPosition * (seek.availableWidth - width)
                        y: seek.topPadding + seek.availableHeight / 2 - height / 2
                        width: Math.round(11 * root.sc)
                        height: width
                        radius: width / 2
                        color: Theme.colors.accent
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: !root.compact
                    spacing: 0

                    Text {
                        text: root.fmt(seek.pressed ? seek.value * Media.length : Media.position)
                        font.family: Theme.font.main
                        font.pointSize: Math.round(Theme.font.small * root.sc)
                        font.features: ({ "tnum": 1 })
                        color: Theme.colors.textSecondary
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.fmt(Media.length)
                        font.family: Theme.font.main
                        font.pointSize: Math.round(Theme.font.small * root.sc)
                        font.features: ({ "tnum": 1 })
                        color: Theme.colors.textSecondary
                    }
                }
            }

            // Centred in every layout - the player switcher that used to sit
            // in this row (and pulled it off-centre) is the corner button now.
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Math.round(root.gap * 0.4)
                spacing: Math.round((root.compact ? 8 : 12) * root.sc)

                TBtn {
                    glyph: "󰒮"
                    size: Math.round((root.compact ? 26 : 30) * root.sc)
                    glyphSize: Math.round(Theme.font.medium * root.sc)
                    can: Media.canGoPrevious
                    onTriggered: Media.previous()
                }
                TBtn {
                    glyph: Media.isPlaying ? "󰏤" : "󰐊"
                    size: Math.round((root.compact ? 32 : 36) * root.sc)
                    glyphSize: Math.round(Theme.font.large * root.sc)
                    primary: true
                    can: root.has
                    onTriggered: Media.togglePlayPause()
                }
                TBtn {
                    glyph: "󰒭"
                    size: Math.round((root.compact ? 26 : 30) * root.sc)
                    glyphSize: Math.round(Theme.font.medium * root.sc)
                    can: Media.canGoNext
                    onTriggered: Media.next()
                }
            }
        }
    }

    // Parked in the corner, out of the layout, so it never shifts the
    // transport row off centre.
    TBtn {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Math.round(root.pad * 0.4)
        visible: root.showCycle && Media.players.length > 1
        glyph: "󰀻"
        size: Math.round(26 * root.sc)
        glyphSize: Math.round(Theme.font.medium * root.sc)
        onTriggered: Media.cyclePlayer()
    }
}
