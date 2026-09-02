pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Full-screen wallpaper / colour-scheme picker for one output: a dim backdrop
// and a centred carousel you step through with the arrow keys (or the wheel, or
// the on-screen chevrons). Every step applies live; Enter keeps it, Escape puts
// back what was there before.
//
// Always mapped, never toggling `visible` — the Osd.qml / LauncherWindow safety
// pattern. What opens and closes is the input mask and the keyboard grab.
PanelWindow {
    id: win

    readonly property bool open: PickerController.openOn === (screen?.name ?? "")
    readonly property bool isTheme: PickerController.kind === "theme"
    readonly property var items: PickerController.items
    readonly property int index: PickerController.index

    // Carousel geometry.
    readonly property int tileW: 440
    readonly property int tileH: 248
    readonly property int stride: tileW + Theme.spacing.large

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:picker"
    WlrLayershell.keyboardFocus: open
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    exclusiveZone: 0
    color: "transparent"
    visible: true

    anchors { top: true; left: true; right: true; bottom: true }

    mask: Region {
        width: win.open ? win.width : 0
        height: win.open ? win.height : 0
    }

    onOpenChanged: if (open) keyCatcher.forceActiveFocus()

    // Light backdrop wash — the scheme's own ground, barely there, the same way
    // the launcher / dashboard just float over the desktop rather than dimming
    // it. A click anywhere off the card cancels.
    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg
        opacity: win.open ? 0.3 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animation.normal } }

        MouseArea {
            anchors.fill: parent
            onClicked: PickerController.cancel()
            onWheel: wheel => PickerController.step(wheel.angleDelta.y > 0 ? -1 : 1)
        }
    }

    FocusScope {
        id: keyCatcher
        anchors.fill: parent
        focus: win.open

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape:      PickerController.cancel(); break;
            case Qt.Key_Return:
            case Qt.Key_Enter:       PickerController.confirm(); break;
            case Qt.Key_Left:
            case Qt.Key_H:           PickerController.step(-1); break;
            case Qt.Key_Right:
            case Qt.Key_L:           PickerController.step(1); break;
            case Qt.Key_R:           PickerController.randomize(); break;
            case Qt.Key_Tab:
                PickerController.setKind(win.isTheme ? "wallpaper" : "theme");
                break;
            default: return;
            }
            event.accepted = true;
        }

        Item {
            id: card

            readonly property int pad: Theme.popup.padding

            anchors.horizontalCenter: parent.horizontalCenter
            y: win.open ? Math.round((parent.height - height) / 2)
                        : Math.round((parent.height - height) / 2) + Theme.spacing.large
            width: Math.min(parent.width - Theme.spacing.huge * 2, 1160)
            height: headerRow.height + carousel.height + footerCol.height
                + Theme.spacing.large * 2 + pad * 2
            opacity: win.open ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: Theme.animation.normal } }
            Behavior on y {
                NumberAnimation { duration: Theme.animation.normal; easing.type: Easing.OutCubic }
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.popup.radius
                color: Theme.popup.background
                border.width: Theme.popup.borderWidth
                border.color: Theme.popup.border

                SoftShadow {}
            }

            // Swallow clicks so they don't reach the backdrop.
            MouseArea { anchors.fill: parent }

            // --- header ---------------------------------------------------
            RowLayout {
                id: headerRow
                anchors.top: parent.top
                anchors.topMargin: card.pad
                anchors.left: parent.left
                anchors.leftMargin: card.pad
                anchors.right: parent.right
                anchors.rightMargin: card.pad
                height: 40
                spacing: Theme.spacing.small

                Repeater {
                    model: [
                        { k: "wallpaper", label: "Wallpaper", icon: "󰸉" },
                        { k: "theme",     label: "Theme",     icon: "󰏘" }
                    ]
                    delegate: Rectangle {
                        id: kindPill
                        required property var modelData
                        readonly property bool on: PickerController.kind === modelData.k
                        implicitWidth: kindRow.implicitWidth + Theme.spacing.medium * 2
                        implicitHeight: 32
                        radius: height / 2
                        color: on ? Theme.colors.accent
                            : kindMouse.containsMouse ? Theme.colors.surfaceVariant
                            : Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                                      Theme.colors.surfaceVariant.b, 0.5)
                        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                        RowLayout {
                            id: kindRow
                            anchors.centerIn: parent
                            spacing: Theme.spacing.tiny
                            Text {
                                text: kindPill.modelData.icon
                                font.family: Theme.font.icon
                                font.pointSize: Theme.font.medium
                                color: kindPill.on ? Theme.colors.bg : Theme.colors.textSecondary
                            }
                            Text {
                                text: kindPill.modelData.label
                                font.family: Theme.font.main
                                font.pointSize: Theme.font.small
                                font.weight: kindPill.on ? Theme.font.semiBold : Theme.font.regular
                                color: kindPill.on ? Theme.colors.bg : Theme.colors.textPrimary
                            }
                        }
                        MouseArea {
                            id: kindMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PickerController.setKind(kindPill.modelData.k)
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: rndRow.implicitWidth + Theme.spacing.medium * 2
                    implicitHeight: 32
                    radius: height / 2
                    color: rndMouse.containsMouse ? Theme.colors.surfaceVariant
                        : Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                                  Theme.colors.surfaceVariant.b, 0.5)
                    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
                    RowLayout {
                        id: rndRow
                        anchors.centerIn: parent
                        spacing: Theme.spacing.tiny
                        Text {
                            text: "󰒟"
                            font.family: Theme.font.icon
                            font.pointSize: Theme.font.medium
                            color: Theme.colors.textSecondary
                        }
                        Text {
                            text: "Random"
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.small
                            color: Theme.colors.textPrimary
                        }
                    }
                    MouseArea {
                        id: rndMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: PickerController.randomize()
                    }
                }

                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: height / 2
                    color: closeMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Theme.font.icon
                        font.pointSize: Theme.font.medium
                        color: Theme.colors.textSecondary
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: PickerController.cancel()
                    }
                }
            }

            // --- carousel ------------------------------------------------
            Item {
                id: carousel
                anchors.top: headerRow.bottom
                anchors.topMargin: Theme.spacing.large
                anchors.left: parent.left
                anchors.leftMargin: card.pad
                anchors.right: parent.right
                anchors.rightMargin: card.pad
                height: win.tileH
                clip: true

                Text {
                    anchors.centerIn: parent
                    visible: win.items.length === 0
                    text: win.isTheme ? "No colour schemes found"
                                      : "No wallpapers — add some in Settings › Appearance"
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.medium
                    color: Theme.colors.textTertiary
                }

                Row {
                    id: strip
                    height: parent.height
                    spacing: Theme.spacing.large
                    x: Math.round(carousel.width / 2 - (win.index * win.stride + win.tileW / 2))
                    Behavior on x {
                        NumberAnimation { duration: Theme.animation.normal; easing.type: Easing.OutCubic }
                    }

                    Repeater {
                        model: win.items

                        delegate: Item {
                            id: tile
                            required property int index
                            required property var modelData
                            readonly property bool active: index === win.index
                            readonly property bool near: Math.abs(index - win.index) <= 2

                            width: win.tileW
                            height: win.tileH
                            opacity: active ? 1 : 0.4
                            scale: active ? 1 : 0.9
                            Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }
                            Behavior on scale { NumberAnimation { duration: Theme.animation.fast } }

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.rounding.large
                                color: Theme.colors.surface1
                                border.width: tile.active ? 2 : 0
                                border.color: Theme.colors.accent
                                clip: true

                                // Wallpaper preview.
                                Image {
                                    anchors.fill: parent
                                    visible: !win.isTheme
                                    source: (!win.isTheme && tile.near)
                                        ? ("file://" + tile.modelData) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    sourceSize.width: 880
                                }

                                // Theme preview: base ground + accent swatches.
                                Column {
                                    anchors.fill: parent
                                    visible: win.isTheme
                                    spacing: 0
                                    Rectangle {
                                        width: parent.width
                                        height: parent.height * 0.62
                                        color: (Appearance.schemes[tile.modelData] ?? {}).base ?? Theme.colors.bg
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 10
                                            Repeater {
                                                model: ["red", "peach", "yellow", "green", "sapphire", "blue", "mauve"]
                                                delegate: Rectangle {
                                                    required property var modelData
                                                    width: 26
                                                    height: 26
                                                    radius: 6
                                                    color: (Appearance.schemes[tile.modelData] ?? {})[modelData] ?? "#888"
                                                }
                                            }
                                        }
                                    }
                                    Rectangle {
                                        width: parent.width
                                        height: parent.height * 0.38
                                        color: (Appearance.schemes[tile.modelData] ?? {}).mantle ?? Theme.colors.surface1
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 8
                                            Repeater {
                                                model: ["surface0", "surface2", "overlay0", "subtext0", "text"]
                                                delegate: Rectangle {
                                                    required property var modelData
                                                    width: 34
                                                    height: 14
                                                    radius: 4
                                                    color: (Appearance.schemes[tile.modelData] ?? {})[modelData] ?? "#888"
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (tile.active)
                                        PickerController.confirm();
                                    else
                                        PickerController.step(tile.index - win.index);
                                }
                            }
                        }
                    }
                }

                // Chevrons.
                Repeater {
                    model: [{ d: -1, g: "󰅁", edge: "l" }, { d: 1, g: "󰅂", edge: "r" }]
                    delegate: Rectangle {
                        id: chev
                        required property var modelData
                        visible: win.items.length > 1
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: modelData.edge === "l" ? parent.left : undefined
                        anchors.right: modelData.edge === "r" ? parent.right : undefined
                        width: 44
                        height: 44
                        radius: height / 2
                        color: chevMouse.containsMouse ? Theme.colors.accent
                            : Qt.rgba(0, 0, 0, 0.45)
                        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
                        Text {
                            anchors.centerIn: parent
                            text: chev.modelData.g
                            font.family: Theme.font.icon
                            font.pointSize: Theme.font.large
                            color: chevMouse.containsMouse ? Theme.colors.bg : Theme.colors.textPrimary
                        }
                        MouseArea {
                            id: chevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PickerController.step(chev.modelData.d)
                        }
                    }
                }
            }

            // --- footer -------------------------------------------------
            ColumnLayout {
                id: footerCol
                anchors.top: carousel.bottom
                anchors.topMargin: Theme.spacing.medium
                anchors.left: parent.left
                anchors.leftMargin: card.pad
                anchors.right: parent.right
                anchors.rightMargin: card.pad
                spacing: 2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (win.items.length === 0)
                            return "";
                        const v = win.items[win.index] ?? "";
                        if (win.isTheme)
                            return v.charAt(0).toUpperCase() + v.slice(1);
                        return String(v).split("/").pop().replace(/\.[^.]+$/, "");
                    }
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.large
                    font.weight: Theme.font.semiBold
                    color: Theme.colors.textPrimary
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: win.items.length > 0
                    text: (win.index + 1) + " / " + win.items.length
                        + "   ·   ← →  browse   ·   Enter  keep   ·   Esc  cancel"
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.small
                    color: Theme.colors.textTertiary
                }
            }
        }
    }
}
