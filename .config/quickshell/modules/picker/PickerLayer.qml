import QtQuick
import Quickshell

// One picker surface per output, mapped up front from shell.qml. They are all
// mapped all the time; PickerController decides which one is open, so only ever
// one holds the keyboard. Mirrors LauncherLayer.
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PickerWindow {
            required property ShellScreen modelData
            screen: modelData
        }
    }
}
