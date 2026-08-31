import QtQuick
import qs.config

// The four MediaLayout variants as little schematics — cover or record, beside
// the text or above it. Used by the Bar page for the media popout and by the
// Widgets page for a placed media widget.
Row {
    id: picker

    property string value: "regular"
    property bool labels: true
    signal picked(string variant)

    readonly property var options: [
        { v: "regular",         name: "Wide",        vertical: false, disc: false },
        { v: "record",          name: "Wide disc",   vertical: false, disc: true },
        { v: "regularVertical", name: "Tall",        vertical: true,  disc: false },
        { v: "recordVertical",  name: "Tall disc",   vertical: true,  disc: true }
    ]

    spacing: Theme.spacing.tiny

    Repeater {
        model: picker.options

        delegate: Column {
            id: opt
            required property var modelData
            readonly property bool on: picker.value === modelData.v

            spacing: 3

            Rectangle {
                width: 56
                height: 44
                radius: Theme.rounding.medium
                color: opt.on ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g,
                                        Theme.colors.accent.b, 0.22)
                    : (tileMouse.containsMouse ? Theme.colors.surfaceVariant
                       : Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                                 Theme.colors.surfaceVariant.b, 0.5))

                Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                Item {
                    anchors.fill: parent
                    anchors.margins: 8

                    // cover / record
                    Rectangle {
                        id: blob
                        width: 15
                        height: 15
                        radius: opt.modelData.disc ? width / 2 : 3
                        color: opt.on ? Theme.colors.accent : Theme.colors.textTertiary
                        anchors.left: opt.modelData.vertical ? undefined : parent.left
                        anchors.verticalCenter: opt.modelData.vertical ? undefined : parent.verticalCenter
                        anchors.top: opt.modelData.vertical ? parent.top : undefined
                        anchors.horizontalCenter: opt.modelData.vertical ? parent.horizontalCenter : undefined

                        // spindle, so a record reads as one at this size
                        Rectangle {
                            visible: opt.modelData.disc
                            anchors.centerIn: parent
                            width: 4
                            height: 4
                            radius: 2
                            color: Theme.colors.surface
                        }
                    }

                    // title / seek / transport stand-ins
                    Column {
                        spacing: 3
                        anchors.left: opt.modelData.vertical ? undefined : blob.right
                        anchors.leftMargin: opt.modelData.vertical ? 0 : 5
                        anchors.verticalCenter: opt.modelData.vertical ? undefined : parent.verticalCenter
                        anchors.top: opt.modelData.vertical ? blob.bottom : undefined
                        anchors.topMargin: opt.modelData.vertical ? 4 : 0
                        anchors.horizontalCenter: opt.modelData.vertical ? parent.horizontalCenter : undefined

                        Rectangle {
                            width: 18
                            height: 2
                            radius: 1
                            color: Theme.colors.textSecondary
                            anchors.horizontalCenter: opt.modelData.vertical ? parent.horizontalCenter : undefined
                        }
                        Rectangle {
                            width: 18
                            height: 2
                            radius: 1
                            color: opt.on ? Theme.colors.accent : Theme.colors.textTertiary
                            anchors.horizontalCenter: opt.modelData.vertical ? parent.horizontalCenter : undefined
                        }
                        Row {
                            spacing: 3
                            anchors.horizontalCenter: parent.horizontalCenter
                            Repeater {
                                model: 3
                                delegate: Rectangle {
                                    required property int index
                                    width: 4
                                    height: 4
                                    radius: 2
                                    color: index === 1
                                        ? (opt.on ? Theme.colors.accent : Theme.colors.textSecondary)
                                        : Theme.colors.textTertiary
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: picker.picked(opt.modelData.v)
                }
            }

            Text {
                visible: picker.labels
                anchors.horizontalCenter: parent.horizontalCenter
                text: opt.modelData.name
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: opt.on ? Theme.colors.accent : Theme.colors.textTertiary
            }
        }
    }
}
