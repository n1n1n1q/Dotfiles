import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.modules.settings

// Full-screen modal editor for the bar layout, shown while BarConfig.editMode
// is on (Settings > Bar toggle, or `qs ipc call bar edit`). One always-mapped,
// click-through overlay per screen — the Osd.qml safety pattern, never toggles
// `visible`; the mask opens to the whole screen only while editing so the drag
// ghost can float over every other window.
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData

            readonly property bool editing: BarConfig.editMode

            // Only hold a Wayland surface + render context while editing (plus a
            // short linger so BarEditStage's fade-out finishes). `shown` lags
            // `editing` by a frame so the stage's enter fade runs off a real
            // 0 -> 1 opacity change instead of being born at 1.
            property bool shown: false
            Timer { id: showTick; interval: 16; onTriggered: win.shown = true }
            Timer { id: closeLinger; interval: Theme.animation.fast + 80 }
            onEditingChanged: {
                if (editing) showTick.restart();
                else { showTick.stop(); shown = false; closeLinger.restart(); }
            }

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:baredit"
            WlrLayershell.keyboardFocus: editing
                ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            // -1: sit at the anchored edge and ignore the bar's exclusive zone,
            // so the editor's bar replica lands exactly over the real bar
            // instead of being pushed below it.
            exclusiveZone: -1
            color: "transparent"
            visible: editing || closeLinger.running

            anchors { top: true; left: true; right: true; bottom: true }

            mask: Region {
                width: win.editing ? win.width : 0
                height: win.editing ? win.height : 0
            }

            // Don't leave a session stuck open if Settings is closed with the
            // toggle still on.
            Connections {
                target: SettingsController
                function onOpenChanged() {
                    if (!SettingsController.open && BarConfig.editMode)
                        BarConfig.commitEdit();
                }
            }

            BarEditStage {
                anchors.fill: parent
                active: win.shown
                panelWindow: win
                screenName: win.modelData.name
            }
        }
    }
}
