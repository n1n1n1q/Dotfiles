pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The one bit of lock state the rest of the shell touches: `locked`. Lock.qml
// binds the WlSessionLock to it; IdleService and a keybind flip it.
//
//   qs ipc call lock lock
//   qs ipc call lock unlock
Singleton {
    id: root

    property bool locked: false
    // Preview the lock surface in an ordinary window — the real WlSessionLock
    // blocks screen capture, so this is the only way to look at it. Password
    // entry is inert in demo mode.
    property bool demo: false

    function lock()   { root.locked = true; }
    function unlock() { root.locked = false; }

    IpcHandler {
        target: "lock"

        function lock(): void { root.lock(); }
        function unlock(): void { root.unlock(); }
        function isLocked(): bool { return root.locked; }
        function demo(): void { root.demo = !root.demo; }
    }
}
