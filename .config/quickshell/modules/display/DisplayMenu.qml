pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.widgets

// Windows-"Win+P"-style pop-up: a centred row of big mode buttons —
// Internal only · Extend · External only — plus a disabled "Duplicate" (niri
// 26.04 can't mirror outputs). One always-mapped overlay window per screen,
// the Osd.qml / PickerWindow safety pattern (never toggles `visible`).
//
// Instantiated once from shell.qml. Open it with `qs ipc call display menu`
// (seeded to Mod+P) or SettingsController → nothing; it stands alone.
Scope {
    id: scope

    readonly property var modes: [
        { id: "internal", glyph: "󰌢", label: "PC screen only",
          hint: "Use the built-in display, external off",
          enabled: DisplayController.hasInternal },
        { id: "extend", glyph: "󰡍", label: "Extend",
          hint: "Both displays, side by side",
          enabled: DisplayController.multiMonitor },
        { id: "external", glyph: "󰍹", label: "Second screen only",
          hint: "Use the external display, built-in off",
          enabled: DisplayController.hasExternal },
        { id: "mirror", glyph: "󰑟", label: "Duplicate",
          hint: "niri can't mirror outputs yet",
          enabled: false }
    ]

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData

            readonly property bool open: DisplayController.openOn === (screen?.name ?? "")

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:display-menu"
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

            // The current mode's index, used as the initial selection.
            property int sel: 0
            onOpenChanged: {
                if (!open)
                    return;
                const cur = DisplayController.currentMode;
                let i = scope.modes.findIndex(m => m.id === cur);
                win.sel = i >= 0 ? i : 1;
                keyCatcher.forceActiveFocus();
            }

            function step(d) {
                let i = win.sel;
                for (let n = 0; n < scope.modes.length; n++) {
                    i = (i + d + scope.modes.length) % scope.modes.length;
                    if (scope.modes[i].enabled) { win.sel = i; return; }
                }
            }
            function commit() {
                const m = scope.modes[win.sel];
                if (m && m.enabled && m.id !== "mirror")
                    DisplayController.apply(m.id);
                DisplayController.hide();
            }

            // No backdrop — it just floats over the desktop like the launcher;
            // a click anywhere off the card dismisses.
            MouseArea {
                anchors.fill: parent
                onClicked: DisplayController.hide()
            }

            FocusScope {
                id: keyCatcher
                anchors.fill: parent
                focus: win.open

                Keys.onPressed: e => {
                    switch (e.key) {
                    case Qt.Key_Escape: DisplayController.hide(); e.accepted = true; break;
                    case Qt.Key_Left:
                    case Qt.Key_H: win.step(-1); e.accepted = true; break;
                    case Qt.Key_Right:
                    case Qt.Key_L: win.step(1); e.accepted = true; break;
                    case Qt.Key_Tab: win.step(1); e.accepted = true; break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                    case Qt.Key_Space: win.commit(); e.accepted = true; break;
                    case Qt.Key_1: win.sel = 0; win.commit(); e.accepted = true; break;
                    case Qt.Key_2: win.sel = 1; win.commit(); e.accepted = true; break;
                    case Qt.Key_3: win.sel = 2; win.commit(); e.accepted = true; break;
                    case Qt.Key_P:
                        if (e.modifiers & Qt.MetaModifier) { win.step(1); e.accepted = true; }
                        break;
                    }
                }

                // The card.
                Rectangle {
                    id: card
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: (parent.height - height) / 2 + (win.open ? 0 : 16)
                    Behavior on y { NumberAnimation { duration: Theme.animation.fast; easing.type: Easing.OutCubic } }
                    opacity: win.open ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }
                    scale: win.open ? 1 : 0.97
                    transformOrigin: Item.Center
                    Behavior on scale { NumberAnimation { duration: Theme.animation.fast; easing.type: Easing.OutCubic } }

                    implicitWidth: inner.implicitWidth + Theme.popup.padding * 2
                    implicitHeight: inner.implicitHeight + Theme.popup.padding * 2
                    radius: Theme.popup.radius
                    color: Theme.popup.background
                    border.width: Theme.popup.borderWidth
                    border.color: Theme.popup.border

                    SoftShadow { z: -1 }

                    ColumnLayout {
                        id: inner
                        anchors.centerIn: parent
                        spacing: Theme.spacing.large

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Display mode"
                            font.family: Theme.font.main
                            font.pointSize: Theme.popup.fontLarge
                            font.weight: Theme.font.semiBold
                            color: Theme.colors.textPrimary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 460
                            visible: !DisplayController.ready
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: "Turn on display editing in Settings › Display first "
                                + "(it splits niri's output blocks into an editable file)."
                            font.family: Theme.font.main
                            font.pointSize: Theme.popup.fontSmall
                            color: Theme.colors.textTertiary
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: Theme.spacing.medium
                            enabled: DisplayController.ready

                            Repeater {
                                model: scope.modes

                                delegate: Rectangle {
                                    id: opt
                                    required property var modelData
                                    required property int index

                                    readonly property bool isSel: win.sel === opt.index
                                    readonly property bool isCurrent: DisplayController.currentMode === opt.modelData.id

                                    implicitWidth: 150
                                    implicitHeight: 128
                                    radius: Theme.rounding.large
                                    opacity: opt.modelData.enabled ? 1 : 0.4
                                    color: opt.isSel ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.16)
                                        : optMouse.containsMouse && opt.modelData.enabled ? Theme.colors.surfaceVariant
                                        : Theme.palette.surface2
                                    border.width: opt.isSel ? 2 : 1
                                    border.color: opt.isSel ? Theme.colors.accent
                                        : opt.isCurrent ? Theme.colors.accentAlt
                                        : Theme.colors.borderSubtle

                                    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        anchors.margins: Theme.spacing.small
                                        width: parent.width - Theme.spacing.medium * 2
                                        spacing: Theme.spacing.tiny

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: opt.modelData.glyph
                                            font.family: Theme.font.icon
                                            font.pointSize: Theme.popup.fontHuge + 6
                                            color: opt.isSel ? Theme.colors.accent : Theme.colors.textSecondary
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                            text: opt.modelData.label
                                            wrapMode: Text.WordWrap
                                            font.family: Theme.font.main
                                            font.pointSize: Theme.popup.fontSmall
                                            font.weight: Theme.font.mediumWeight
                                            color: Theme.colors.textPrimary
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                            text: opt.isCurrent ? "Current" : opt.modelData.hint
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: 2
                                            font.family: Theme.font.main
                                            font.pointSize: Theme.popup.fontTiny
                                            color: opt.isCurrent ? Theme.colors.accentAlt : Theme.colors.textTertiary
                                        }
                                    }

                                    MouseArea {
                                        id: optMouse
                                        anchors.fill: parent
                                        enabled: opt.modelData.enabled
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { win.sel = opt.index; win.commit(); }
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "←  →  choose    ·    Enter  apply    ·    Esc  close"
                            font.family: Theme.font.main
                            font.pointSize: Theme.popup.fontTiny
                            color: Theme.colors.textTertiary
                        }
                    }
                }
            }
        }
    }
}
