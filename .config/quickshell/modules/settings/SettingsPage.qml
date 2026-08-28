import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

// Scaffold every settings page builds on: a scrolling column with a heading
// block at the top. Page content is declared as children and stacks below it.
ScrollView {
    id: page

    default property alias body: col.data
    property string heading: ""
    property string blurb: ""

    contentWidth: availableWidth
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ColumnLayout {
        id: col
        width: page.availableWidth
        spacing: Theme.spacing.large

        ColumnLayout {
            visible: page.heading.length > 0
            Layout.fillWidth: true
            Layout.bottomMargin: Theme.spacing.tiny
            spacing: 2

            Text {
                text: page.heading
                font.family: Theme.font.main
                font.pointSize: Theme.font.xlarge + 4
                font.weight: Theme.font.bold
                color: Theme.colors.textPrimary
            }

            Text {
                visible: page.blurb.length > 0
                Layout.fillWidth: true
                text: page.blurb
                wrapMode: Text.WordWrap
                font.family: Theme.font.main
                font.pointSize: Theme.font.medium
                color: Theme.colors.textTertiary
            }
        }
    }
}
