import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings

SettingsPage {
    heading: "Bar"
    blurb: "What sits where along the top bar. Reordering is the next thing to build."

    SettingsGroup {
        caption: "Zones"

        Repeater {
            model: [
                { icon: "󰁍", title: "Left edge", sub: "Window title" },
                { icon: "󰅁", title: "Left cluster", sub: "System stats · Media" },
                { icon: "󰆤", title: "Centre", sub: "Workspaces" },
                { icon: "󰅂", title: "Right cluster", sub: "Clock · Battery" },
                { icon: "󰁔", title: "Right edge", sub: "Tray" }
            ]
            delegate: SettingsRow {
                required property var modelData
                icon: modelData.icon
                title: modelData.title
                subtitle: modelData.sub
            }
        }
    }

    SettingsGroup {
        caption: "Options"

        SettingsRow {
            icon: "󰉺"
            title: "Drag to reorder"
            subtitle: "For now the arrangement lives in modules/bar/Bar.qml"
            Text {
                text: "Soon"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
        }
    }
}
