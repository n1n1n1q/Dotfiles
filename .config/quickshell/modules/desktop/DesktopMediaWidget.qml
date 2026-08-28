import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// Desktop now-playing card: cover, title/artist, thin transport. props:
// scale (real).
Item {
    id: root

    property var props: ({})
    readonly property real sc: props.scale ?? 1.0
    readonly property bool has: Media.activePlayer !== null

    implicitWidth: 300 * sc
    implicitHeight: rowL.implicitHeight + 20 * sc

    Rectangle {
        anchors.fill: parent
        radius: Theme.rounding.large
        color: Qt.rgba(Theme.colors.background.r, Theme.colors.background.g,
                       Theme.colors.background.b, 0.5)
    }

    RowLayout {
        id: rowL
        anchors.fill: parent
        anchors.margins: 10 * root.sc
        spacing: 10 * root.sc

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 56 * root.sc
            implicitHeight: 56 * root.sc
            radius: Theme.rounding.small
            color: Theme.colors.surfaceVariant
            clip: true

            Image {
                anchors.fill: parent
                source: Media.artUrl
                fillMode: Image.PreserveAspectCrop
                cache: false
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: Media.artUrl.length === 0
                text: "󰝚"
                font.family: Theme.font.icon
                font.pointSize: Math.round(20 * root.sc)
                color: Theme.colors.textTertiary
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.has ? Media.title : "Nothing playing"
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Math.round(12 * root.sc)
                font.weight: Theme.font.semiBold
                color: Theme.colors.textPrimary
            }
            Text {
                Layout.fillWidth: true
                visible: root.has && Media.artist.length > 0
                text: Media.artist
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Math.round(10 * root.sc)
                color: Theme.colors.textSecondary
            }

            RowLayout {
                Layout.topMargin: 2
                spacing: 12 * root.sc

                Repeater {
                    model: [
                        { g: "󰒮", can: Media.canGoPrevious, act: () => Media.previous() },
                        { g: Media.isPlaying ? "󰏤" : "󰐊", can: root.has, act: () => Media.togglePlayPause() },
                        { g: "󰒭", can: Media.canGoNext, act: () => Media.next() }
                    ]
                    delegate: Text {
                        required property var modelData
                        text: modelData.g
                        font.family: Theme.font.icon
                        font.pointSize: Math.round(13 * root.sc)
                        color: modelData.can ? Theme.colors.textPrimary : Theme.colors.textTertiary
                        opacity: modelData.can ? 1 : 0.4

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            enabled: modelData.can
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.act()
                        }
                    }
                }
            }
        }
    }
}
