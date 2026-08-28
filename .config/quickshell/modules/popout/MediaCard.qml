import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import qs.config
import qs.services

// end-4-style now-playing card: blurred album art behind, art thumbnail +
// track text, a draggable seek bar and prev / play-pause / next. Opened from
// the bar's media widget label.
Rectangle {
    id: root

    readonly property bool has: Media.activePlayer !== null

    function fmt(us) {
        if (!us || us <= 0) return "0:00";
        const s = Math.floor(us / 1000000);
        const m = Math.floor(s / 60);
        return m + ":" + String(s % 60).padStart(2, "0");
    }

    implicitWidth: 344
    implicitHeight: 168
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
    MultiEffect {
        anchors.fill: parent
        source: art
        visible: art.status === Image.Ready
        blurEnabled: true
        blur: 1
        blurMax: 48
        brightness: -0.25
        saturation: 0.1
    }
    Rectangle {
        anchors.fill: parent
        color: Theme.popup.background
        opacity: art.status === Image.Ready ? 0.55 : 1
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.popup.padding
        spacing: Theme.spacing.medium

        // cover thumbnail
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 108
            implicitHeight: 108
            radius: Theme.rounding.medium
            color: Theme.colors.surfaceVariant
            clip: true

            Image {
                anchors.fill: parent
                source: Media.artUrl
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: "󰝚"
                font.family: Theme.font.icon
                font.pointSize: Theme.font.huge + 6
                color: Theme.colors.textTertiary
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.spacing.tiny

            Text {
                Layout.fillWidth: true
                text: root.has ? Media.title : "Nothing playing"
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.font.medium
                font.weight: Theme.font.semiBold
                color: Theme.colors.textPrimary
            }
            Text {
                Layout.fillWidth: true
                visible: root.has && (Media.artist.length > 0 || Media.album.length > 0)
                text: [Media.artist, Media.album].filter(s => s && s.length > 0).join("  ·  ")
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textSecondary
            }

            Item { Layout.fillHeight: true }

            // seek bar
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacing.tiny
                spacing: Theme.spacing.small
                visible: root.has

                Text {
                    text: root.fmt(seek.pressed ? seek.value * Media.length : Media.position)
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.tiny + 1
                    font.features: ({ "tnum": 1 })
                    color: Theme.colors.textSecondary
                }

                Slider {
                    id: seek
                    Layout.fillWidth: true
                    enabled: Media.length > 0 && (Media.activePlayer?.positionSupported ?? false)
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
                        height: 4
                        radius: 2
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
                        width: 12
                        height: 12
                        radius: 6
                        color: Theme.colors.accent
                    }
                }

                Text {
                    text: root.fmt(Media.length)
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.tiny + 1
                    font.features: ({ "tnum": 1 })
                    color: Theme.colors.textSecondary
                }
            }

            // transport
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.spacing.tiny
                spacing: Theme.spacing.medium

                component TBtn: Rectangle {
                    id: tb
                    property string glyph: ""
                    property bool primary: false
                    property bool can: true
                    signal triggered()
                    implicitWidth: primary ? 36 : 30
                    implicitHeight: primary ? 36 : 30
                    radius: height / 2
                    color: primary ? Theme.colors.accent
                        : (tbMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent")
                    opacity: can ? 1 : 0.35
                    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
                    Text {
                        anchors.centerIn: parent
                        text: tb.glyph
                        font.family: Theme.font.icon
                        font.pointSize: tb.primary ? Theme.font.large : Theme.font.medium
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

                Item { Layout.fillWidth: true }

                TBtn {
                    glyph: "󰒮"
                    can: Media.canGoPrevious
                    onTriggered: Media.previous()
                }
                TBtn {
                    glyph: Media.isPlaying ? "󰏤" : "󰐊"
                    primary: true
                    can: root.has
                    onTriggered: Media.togglePlayPause()
                }
                TBtn {
                    glyph: "󰒭"
                    can: Media.canGoNext
                    onTriggered: Media.next()
                }

                Item { Layout.fillWidth: true }

                TBtn {
                    glyph: "󰀻"
                    visible: Media.players.length > 1
                    onTriggered: Media.cyclePlayer()
                }
            }
        }
    }
}
