import QtQuick
import QtQuick.Controls
import qs.config

// Flat pill dropdown. The Basic style's stock ComboBox paints a bordered white
// box that fights everything around it, so every part is restyled here: the
// field, the chevron, the popup and its rows.
ComboBox {
    id: root

    // Shown when `currentIndex` is -1 — a saved value the model no longer has.
    property string fallbackText: ""

    font.family: Theme.font.main
    font.pointSize: Theme.font.small
    implicitHeight: 30
    leftPadding: Theme.spacing.normal
    rightPadding: 28
    topPadding: 0
    bottomPadding: 0

    displayText: currentIndex >= 0 ? currentText : fallbackText

    background: Rectangle {
        radius: height / 2
        color: root.hovered || root.popup.visible
            ? Theme.colors.surfaceVariant
            : Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                      Theme.colors.surfaceVariant.b, 0.55)

        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
    }

    contentItem: Text {
        text: root.displayText
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        font: root.font
        color: Theme.colors.textPrimary
    }

    indicator: Text {
        x: root.width - width - Theme.spacing.normal
        y: (root.height - height) / 2
        text: "󰅀"
        font.family: Theme.font.icon
        font.pointSize: Theme.font.tiny
        color: Theme.colors.textTertiary
    }

    delegate: ItemDelegate {
        required property var modelData
        required property int index

        width: ListView.view.width
        implicitHeight: 30
        highlighted: root.highlightedIndex === index

        contentItem: Text {
            text: root.textRole && typeof modelData === "object"
                ? modelData[root.textRole]
                : modelData
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            color: Theme.colors.textPrimary
        }

        background: Rectangle {
            radius: Theme.rounding.medium
            color: parent.highlighted ? Theme.colors.surfaceVariant : "transparent"
        }
    }

    popup: Popup {
        y: root.height + 4
        width: root.width
        implicitHeight: Math.min(contentItem.implicitHeight + 8, 280)
        padding: 4

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle {
            radius: Theme.rounding.large
            color: Theme.colors.surface
            border.width: 1
            border.color: Qt.rgba(Theme.colors.borderSubtle.r, Theme.colors.borderSubtle.g,
                                  Theme.colors.borderSubtle.b, 0.5)
        }
    }
}
