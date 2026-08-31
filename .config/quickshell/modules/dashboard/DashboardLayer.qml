import QtQuick
import Quickshell
import qs.config

// One dashboard panel per screen, instantiated up front from shell.qml.
//
// It used to be built on demand with Qt.createComponent from inside the bar's
// window-title widget. That had two problems: hot reload never rebuilt the
// imperative instance (so the panel kept running whatever code it was born
// with), and the bar layout editor - which instantiates a replica of every bar
// widget, window title included - quietly spawned a second one.
//
// The window itself starts hidden; WindowTitle and `qs ipc call dashboard ...`
// drive it through DashboardConfig's request signals.
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        DashboardWindow {
            required property ShellScreen modelData
            screen: modelData
            barHeight: Theme.bar.height
        }
    }
}
