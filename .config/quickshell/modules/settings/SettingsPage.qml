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
    property string icon: ""
    // Overlay layer above the page content (drag ghosts, etc.).
    property alias overlay: overlayItem

    contentWidth: availableWidth
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    // StackLayout hides the inactive pages; scroll back to the top whenever
    // this one is shown again so a page always opens at its heading.
    onVisibleChanged: if (visible && contentItem) contentItem.contentY = 0

    ColumnLayout {
        id: col
        width: page.availableWidth
        spacing: Theme.spacing.large

        RowLayout {
            visible: page.heading.length > 0
            Layout.fillWidth: true
            Layout.bottomMargin: Theme.spacing.small
            spacing: Theme.spacing.normal

            Rectangle {
                visible: page.icon.length > 0
                Layout.alignment: Qt.AlignTop
                implicitWidth: 44
                implicitHeight: 44
                radius: Theme.rounding.medium
                color: Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g,
                               Theme.colors.accent.b, 0.16)

                Text {
                    anchors.centerIn: parent
                    text: page.icon
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.xlarge + 4
                    color: Theme.colors.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
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
                    color: Theme.colors.textSecondary
                }
            }
        }
    }

    // Sits above the page content; drag ghosts reparent here.
    Item {
        id: overlayItem
        parent: page.contentItem
        anchors.fill: parent
        z: 999
    }
}
