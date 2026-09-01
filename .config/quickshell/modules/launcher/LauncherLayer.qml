import QtQuick
import Quickshell

// One launcher surface per output, instantiated up front from shell.qml.
// They are all mapped all the time; LauncherController decides which one is
// actually open, so only ever one of them holds the keyboard.
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        LauncherWindow {
            required property ShellScreen modelData
            screen: modelData
        }
    }
}
