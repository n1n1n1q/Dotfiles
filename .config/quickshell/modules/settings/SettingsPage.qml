import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

// Scaffold every settings page builds on: a scrolling column of sections.
//
// There is deliberately no page-title block here — the sidebar already says
// which page you are on, so the content starts straight in on the first
// section header. `heading` and `icon` are kept as page metadata (the window
// reads them for the nav); only `blurb` renders, as a dim intro line.
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
    bottomPadding: Theme.spacing.large
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    // StackLayout hides the inactive pages; scroll back to the top whenever
    // this one is shown again so a page always opens at its first section.
    onVisibleChanged: if (visible && contentItem) contentItem.contentY = 0

    ColumnLayout {
        id: col
        width: page.availableWidth
        spacing: Theme.spacing.medium

        Text {
            visible: page.blurb.length > 0
            Layout.fillWidth: true
            Layout.leftMargin: Theme.spacing.small
            Layout.rightMargin: Theme.spacing.small
            Layout.bottomMargin: -Theme.spacing.tiny
            text: page.blurb
            wrapMode: Text.WordWrap
            lineHeight: 1.25
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            color: Theme.colors.textTertiary
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
