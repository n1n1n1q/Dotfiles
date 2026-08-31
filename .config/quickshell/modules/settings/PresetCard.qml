import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.settings

// One saved setup in the Presets grid: the swatch strip of the scheme it
// restores, its name, a one-line summary of what else is in it, and a check
// while the live config still matches it. Click the body to apply; the actions
// that fade in on hover overwrite it with the current setup or delete it.
Rectangle {
    id: root

    required property string presetName
    required property var body

    readonly property bool active: Presets.activeName === presetName
    readonly property string schemeName: root.body?.appearance?.scheme ?? ""
    readonly property var colors: Appearance.schemes[schemeName] ?? ({})
    // The preset names a scheme that isn't installed here any more. It still
    // applies — the shell just falls back to the default palette — so the card
    // says so instead of showing a strip of placeholder greys.
    readonly property bool schemeMissing: schemeName.length > 0
        && Appearance.schemes[schemeName] === undefined

    // "rosepine · bar top · 2 widgets" — enough to tell two presets apart
    // without applying them.
    readonly property string summary: {
        const parts = [];
        if (schemeName.length > 0)
            parts.push(schemeName);
        const edge = root.body?.bar?.style?.edge;
        if (edge)
            parts.push("bar " + edge);
        const n = (root.body?.desktop?.widgets ?? []).length;
        parts.push(n === 1 ? "1 widget" : n + " widgets");
        return parts.join(" · ");
    }

    // Deleting throws away a setup that may exist nowhere else, so the button
    // swaps the card for a confirmation rather than acting on the first click.
    property bool confirming: false

    implicitWidth: 176
    implicitHeight: 112
    radius: Theme.rounding.large
    color: active ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g,
                            Theme.colors.accent.b, 0.14)
        : hover.hovered ? Theme.colors.surfaceVariant
        : Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                  Theme.colors.surfaceVariant.b, 0.45)
    border.width: active ? 2 : 0
    border.color: Theme.colors.accent
    clip: true

    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animation.fast } }

    // Stays hovered while the cursor is over the action buttons too — their own
    // MouseAreas would otherwise pull the hover out from under the row that
    // reveals them.
    HoverHandler { id: hover }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacing.small
        spacing: Theme.spacing.tiny

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: Theme.rounding.medium
            color: root.colors.base ?? Theme.colors.surfaceVariant

            Row {
                anchors.centerIn: parent
                visible: !root.schemeMissing
                spacing: 4

                Repeater {
                    model: [root.colors.red, root.colors.peach, root.colors.green,
                            root.colors.blue, root.colors.mauve]
                    delegate: Rectangle {
                        required property var modelData
                        width: 13
                        height: 13
                        radius: 4
                        color: modelData ?? "#888888"
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.schemeMissing
                text: "scheme missing"
                font.family: Theme.font.main
                font.pointSize: Theme.font.tiny
                color: Theme.colors.textTertiary
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.tiny

            Text {
                Layout.fillWidth: true
                text: root.presetName
                elide: Text.ElideRight
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                font.weight: root.active ? Theme.font.semiBold : Theme.font.mediumWeight
                color: Theme.colors.textPrimary
            }

            Text {
                visible: root.active
                text: "󰄬"
                font.family: Theme.font.icon
                font.pointSize: Theme.font.medium
                color: Theme.colors.accent
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.summary
            elide: Text.ElideRight
            font.family: Theme.font.main
            font.pointSize: Theme.font.tiny
            color: Theme.colors.textTertiary
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.confirming
        cursorShape: Qt.PointingHandCursor
        onClicked: Presets.apply(root.presetName)
    }

    // Overwrite / delete, tucked into the swatch strip's top-right corner on a
    // scrim so they stay readable over any palette.
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.spacing.small + 2
        implicitWidth: actions.implicitWidth + 6
        implicitHeight: actions.implicitHeight + 2
        radius: height / 2
        color: Qt.rgba(Theme.colors.surface.r, Theme.colors.surface.g,
                       Theme.colors.surface.b, 0.85)
        opacity: hover.hovered && !root.confirming ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }

        Row {
            id: actions
            anchors.centerIn: parent
            spacing: 0

            IconButton {
                icon: "󰆓"
                onClicked: Presets.save(root.presetName)
            }
            IconButton {
                icon: "󰩹"
                danger: true
                onClicked: root.confirming = true
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.confirming
        radius: parent.radius
        color: Theme.colors.surface

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - Theme.spacing.normal * 2
            spacing: Theme.spacing.small

            Text {
                Layout.fillWidth: true
                text: "Delete “" + root.presetName + "”?"
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textPrimary
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacing.small

                PillButton {
                    text: "Keep"
                    onClicked: root.confirming = false
                }
                PillButton {
                    text: "Delete"
                    danger: true
                    onClicked: {
                        root.confirming = false;
                        Presets.remove(root.presetName);
                    }
                }
            }
        }
    }

    // Never leave a card sitting in its confirm state after the pointer walks
    // away — the next click on it would otherwise land on "Delete".
    onVisibleChanged: if (!visible) confirming = false
    Connections {
        target: hover
        function onHoveredChanged() { if (!hover.hovered) root.confirming = false; }
    }
}
