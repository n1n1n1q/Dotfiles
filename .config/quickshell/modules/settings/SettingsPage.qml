import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

// Scaffold every settings page builds on: a scrolling, centred, width-capped
// column with a big page title at the top (Caelestia-"Nexus" style), then the
// page's own sections. `heading` names the page; `blurb` is a dim intro line.
ScrollView {
    id: page

    default property alias body: col.data
    property string heading: ""
    property string blurb: ""
    property string icon: ""
    // Overlay layer above the page content (drag ghosts, etc.).
    property alias overlay: overlayItem

    // How wide the content column is allowed to get on a wide window.
    readonly property int contentCap: 840

    contentWidth: availableWidth
    clip: true
    bottomPadding: Theme.spacing.xlarge
    // Reserve real width for the vertical scrollbar instead of letting it
    // overlay the content — the Basic style's scrollbar keeps an interactive
    // hit-strip even at 0 opacity, which was swallowing clicks on anything
    // that reached the page's right edge (trailing toggles, etc).
    rightPadding: vBar.visible ? vBar.width + Theme.spacing.tiny : 0
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical: ScrollBar {
        id: vBar
        policy: ScrollBar.AsNeeded
    }

    // StackLayout hides the inactive pages; scroll back to the top whenever
    // this one is shown again so a page always opens at its first section.
    onVisibleChanged: if (visible && contentItem) contentItem.contentY = 0

    Item {
        id: centerer
        width: page.availableWidth
        implicitHeight: col.implicitHeight

        ColumnLayout {
            id: col
            width: Math.min(page.contentCap, centerer.width)
            x: Math.round((centerer.width - width) / 2)
            spacing: Theme.spacing.large

            // --- page title -------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Theme.spacing.small
                spacing: Theme.spacing.tiny

                Text {
                    visible: page.heading.length > 0
                    Layout.fillWidth: true
                    text: page.heading
                    elide: Text.ElideRight
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.display
                    font.weight: Theme.font.bold
                    color: Theme.colors.textPrimary
                }

                Text {
                    visible: page.blurb.length > 0
                    Layout.fillWidth: true
                    text: page.blurb
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.medium
                    color: Theme.colors.textTertiary
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
