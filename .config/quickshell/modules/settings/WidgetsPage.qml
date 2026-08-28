import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings

SettingsPage {
    id: page
    heading: "Widgets"
    blurb: "Every widget the bar can show. Place them into groups on the Bar page."

    function placements(id) {
        let n = 0;
        for (const sec of [BarConfig.left, BarConfig.center, BarConfig.right])
            for (const g of sec)
                n += (g.widgets ?? []).filter(w => w === id).length;
        return n;
    }

    SettingsGroup {
        caption: "Catalogue"

        Repeater {
            model: BarConfig.catalogue

            delegate: SettingsRow {
                required property var modelData
                icon: modelData.icon
                title: modelData.name
                subtitle: modelData.desc

                Text {
                    readonly property int n: page.placements(modelData.id)
                    text: n === 0 ? "Not placed" : n === 1 ? "On the bar" : (n + "×")
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.small
                    color: n === 0 ? Theme.colors.textTertiary : Theme.colors.accent
                }
            }
        }
    }

    SettingsGroup {
        caption: "Style"

        SettingsRow {
            icon: "󰀉"
            title: "Circular gauge look"
            subtitle: "Theme.widget.circularStyle — 'filled' pie or 'ring'"
            Text {
                text: Theme.widget.circularStyle
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textSecondary
            }
        }
    }
}
