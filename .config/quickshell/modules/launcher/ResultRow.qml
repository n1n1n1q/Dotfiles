import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config

// One line of the launcher's result list: an icon, what the thing is called,
// what it is underneath, and — on the row you're about to fire — the key that
// fires it.
//
// The icon is either a themed image (apps and their actions) or a Nerd Font
// glyph (the command / math / web rows), and a result carries exactly one of
// the two, so there's no arbitration to do here.
Rectangle {
    id: row

    required property var result
    property bool selected: false

    signal activated()
    // Right-click on an app row — carries the click point in window coords so
    // the launcher can drop its little pin/hide menu there.
    signal contextRequested(var windowPos)

    implicitHeight: Theme.launcher.rowHeight
    radius: Theme.rounding.large

    // Selected wins over hovered: the keyboard is driving, and a pointer
    // resting somewhere else in the list shouldn't look like it is.
    color: selected ? Theme.colors.accent
        : (mouse.containsMouse ? Theme.colors.surfaceVariant : "transparent")

    Behavior on color {
        ColorAnimation { duration: Theme.animation.fast }
    }

    readonly property color ink: selected ? Theme.colors.bg : Theme.colors.textPrimary
    readonly property color inkDim: selected
        ? Qt.rgba(Theme.colors.bg.r, Theme.colors.bg.g, Theme.colors.bg.b, 0.7)
        : Theme.colors.textTertiary

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mev => {
            if (mev.button === Qt.RightButton) {
                if (row.result.kind === "app")
                    row.contextRequested(row.mapToItem(null, mev.x, mev.y));
                return;
            }
            row.activated();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.normal
        anchors.rightMargin: Theme.spacing.normal
        spacing: Theme.spacing.normal

        // --- icon ---------------------------------------------------------
        Item {
            Layout.preferredWidth: Theme.launcher.iconSize
            Layout.preferredHeight: Theme.launcher.iconSize
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                anchors.fill: parent
                visible: row.result.icon.length > 0 && row.result.kind !== "wallpaper"
                // Synchronous: themed icons go through Qt's SVG icon engine,
                // which is not thread-safe (see Tray.qml).
                asynchronous: false
                source: row.result.icon
            }

            // Wallpaper rows show the image itself, cropped to the icon square.
            Rectangle {
                anchors.fill: parent
                visible: row.result.kind === "wallpaper"
                radius: Theme.rounding.small
                color: Theme.colors.surfaceVariant
                clip: true
                Image {
                    anchors.fill: parent
                    source: row.result.kind === "wallpaper"
                        ? ("file://" + row.result.icon) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: 96
                }
            }

            Text {
                anchors.centerIn: parent
                visible: row.result.glyph.length > 0
                text: row.result.glyph
                font.family: Theme.font.icon
                font.pointSize: Theme.font.xlarge
                color: row.selected ? Theme.colors.bg : Theme.colors.accent
            }

            // Colour-scheme rows carry a swatch strip in place of an icon.
            Column {
                anchors.centerIn: parent
                visible: (row.result.swatch ?? []).length > 0
                spacing: 3
                Repeater {
                    model: row.result.swatch ?? []
                    delegate: Rectangle {
                        required property var modelData
                        width: 22
                        height: 5
                        radius: 2
                        color: modelData
                    }
                }
            }
        }

        // --- name + subtitle ----------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: row.result.name
                elide: Text.ElideRight
                font.family: row.result.mono ? Theme.font.mono : Theme.font.main
                font.pointSize: Theme.font.medium
                color: row.ink
            }

            Text {
                Layout.fillWidth: true
                visible: row.result.sub.length > 0
                text: row.result.sub
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: row.inkDim
            }
        }

        // Pinned-to-favourites marker.
        Text {
            Layout.alignment: Qt.AlignVCenter
            visible: row.result.favorite === true
            text: "󰐃"
            font.family: Theme.font.icon
            font.pointSize: Theme.font.small
            color: row.selected ? Theme.colors.bg : Theme.colors.accent
        }

        // --- what pressing Enter would do ----------------------------------
        // The selected row says it with the key drawn in; every other row just
        // labels itself, and apps don't bother — a list of apps saying "App"
        // eleven times over is noise.
        Text {
            Layout.alignment: Qt.AlignVCenter
            visible: !row.selected && row.result.kind !== "app"
            text: row.result.type
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            color: Theme.colors.textTertiary
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            visible: row.selected
            implicitWidth: verb.implicitWidth + Theme.spacing.normal * 2
            implicitHeight: 22
            radius: height / 2
            color: Qt.rgba(Theme.colors.bg.r, Theme.colors.bg.g, Theme.colors.bg.b, 0.22)

            RowLayout {
                id: verb
                anchors.centerIn: parent
                spacing: Theme.spacing.tiny

                Text {
                    text: "󰌑"
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.small
                    color: Theme.colors.bg
                }

                Text {
                    text: row.result.verb
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.small
                    color: Theme.colors.bg
                }
            }
        }
    }
}
