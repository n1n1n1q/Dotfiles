import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.widgets

// One entry in a TrayMenuCard - a DBusMenu item exposed as a QsMenuEntry.
// Recurses into itself for a submenu (`hasChildren`), expanding in place
// accordion-style rather than opening a native flyout.
ColumnLayout {
    id: root

    // Not `required`: the recursive submenu path below assigns this after
    // the Loader creates the object rather than at creation time, so every
    // read of it here has to tolerate a momentary null.
    property var entry: null

    property bool expanded: false

    Layout.fillWidth: true
    spacing: 1

    // --- separator ---------------------------------------------------------
    Rectangle {
        visible: root.entry?.isSeparator ?? false
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.tiny
        Layout.bottomMargin: Theme.spacing.tiny
        implicitHeight: 1
        color: Theme.colors.borderSubtle
    }

    // --- the row -------------------------------------------------------------
    Rectangle {
        visible: root.entry != null && !root.entry.isSeparator
        Layout.fillWidth: true
        implicitHeight: 34
        radius: Theme.rounding.small
        opacity: (root.entry?.enabled ?? true) ? 1 : 0.4
        color: hover.hovered ? Theme.colors.surfaceVariant : "transparent"

        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

        HoverHandler { id: hover; enabled: root.entry?.enabled ?? false }
        TapHandler {
            enabled: root.entry?.enabled ?? false
            onTapped: {
                if (root.entry.hasChildren)
                    root.expanded = !root.expanded;
                else
                    root.entry.triggered();
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing.normal
            anchors.rightMargin: Theme.spacing.normal
            spacing: Theme.spacing.small

            GlyphIcon {
                Layout.preferredWidth: 16
                visible: (root.entry?.buttonType ?? QsMenuButtonType.None) !== QsMenuButtonType.None
                text: root.entry?.checkState !== Qt.Unchecked
                    ? (root.entry?.buttonType === QsMenuButtonType.RadioButton ? "󰐊" : "󰄬")
                    : ""
                font.family: Theme.font.icon
                font.pointSize: Theme.popup.fontSmall
                color: Theme.colors.accent
            }

            Text {
                Layout.fillWidth: true
                text: root.entry?.text ?? ""
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.popup.fontSmall
                color: Theme.colors.textPrimary
            }

            GlyphIcon {
                visible: root.entry?.hasChildren ?? false
                text: root.expanded ? "󰅃" : "󰅀"
                font.family: Theme.font.icon
                font.pointSize: Theme.popup.fontSmall
                color: Theme.colors.textTertiary
            }
        }
    }

    // --- submenu, indented -----------------------------------------------
    Loader {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacing.medium
        active: (root.entry?.hasChildren ?? false) && root.expanded
        sourceComponent: Column {
            width: parent ? parent.width : 0
            spacing: 1

            QsMenuOpener {
                id: subOpener
                menu: root.entry
            }

            Repeater {
                model: subOpener.children
                // A component can't directly instantiate itself in the same
                // file ("instantiated recursively") — loading the row by URL
                // instead of inline sourceComponent sidesteps that check.
                delegate: Loader {
                    id: subRowLoader
                    required property var modelData
                    width: parent ? parent.width : 0
                    source: Qt.resolvedUrl("TrayMenuRow.qml")
                    onLoaded: item.entry = subRowLoader.modelData
                }
            }
        }
    }
}
