import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.modules.settings

SettingsPage {
    id: page
    heading: "Welcome, " + System.userName
    icon: "󰋜"
    blurb: "The control panel for the shell. The rail on the left runs in that "
        + "order: how the shell looks, what each of its surfaces is made of, "
        + "then the system and its devices."

    signal navigate(string slug)

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Theme.spacing.medium
        rowSpacing: Theme.spacing.medium

        Repeater {
            model: [
                { slug: "appearance", icon: "󰏘", title: "Appearance", desc: "Colour scheme, wallpaper and fonts" },
                { slug: "bar",        icon: "󰟀", title: "Bar",        desc: "Layout of the top bar" },
                { slug: "wifi",       icon: "󰤨", title: "Wi‑Fi",      desc: "Wireless networking" },
                { slug: "sound",      icon: "󰕾", title: "Sound",      desc: "Output and input levels" }
            ]

            delegate: Rectangle {
                id: card
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredHeight: 92
                color: hov.containsMouse ? Theme.colors.surfaceVariant : Theme.colors.surface
                radius: Theme.rounding.large

                Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacing.normal
                    spacing: Theme.spacing.normal

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 40
                        implicitHeight: 40
                        radius: Theme.rounding.small
                        color: Theme.colors.surfaceVariant
                        Text {
                            anchors.centerIn: parent
                            text: card.modelData.icon
                            font.family: Theme.font.icon
                            font.pointSize: Theme.font.xlarge
                            color: Theme.colors.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: card.modelData.title
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.medium
                            font.weight: Theme.font.semiBold
                            color: Theme.colors.textPrimary
                        }
                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.desc
                            wrapMode: Text.WordWrap
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.small
                            color: Theme.colors.textTertiary
                        }
                    }
                }

                MouseArea {
                    id: hov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.navigate(card.modelData.slug)
                }
            }
        }
    }
}
