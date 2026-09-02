pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.config
import qs.services

// The session lock. One WlSessionLock bound to LockController.locked, with a
// LockSurface per output (WlSessionLockSurface fans out automatically). PAM and
// the typed password buffer are shared here so every monitor's surface types
// into the same field.
//
// Instantiated once from shell.qml.
Scope {
    id: root

    // Shared across surfaces.
    property string buffer: ""
    property string errorText: ""
    readonly property bool busy: pam.active
    readonly property bool maxedOut: root._maxed
    property bool _maxed: false

    signal failed()   // LockSurface listens → shake

    function typeChar(c) {
        if (root._maxed) return;
        root.errorText = "";
        root.buffer += c;
    }
    function backspace() { root.buffer = root.buffer.slice(0, -1); }
    function clearBuffer() { root.buffer = ""; }
    function submit() {
        if (pam.active || root.buffer.length === 0 || root._maxed) return;
        pam.start();
    }

    // Preview window (qs ipc call lock demo) — the LockSurface rendered in an
    // ordinary overlay so it can be inspected / screenshotted.
    Loader {
        active: LockController.demo
        sourceComponent: PanelWindow {
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            anchors { top: true; left: true; right: true; bottom: true }
            color: "transparent"
            LockSurface {
                anchors.fill: parent
                lock: root
                screenName: ""
            }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) LockController.demo = false;
            }
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: LockController.locked

        WlSessionLockSurface {
            id: surface
            color: "transparent"

            LockSurface {
                anchors.fill: parent
                lock: root
                screenName: surface.screen?.name ?? ""
            }
        }
    }

    PamContext {
        id: pam
        config: "quickshell"
        configDirectory: Quickshell.shellPath("assets/pam.d")

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(root.buffer);
        }

        onCompleted: res => {
            if (res === PamResult.Success) {
                root.buffer = "";
                root.errorText = "";
                LockController.unlock();
                return;
            }
            root.buffer = "";
            if (res === PamResult.MaxTries) {
                root._maxed = true;
                root.errorText = "Too many attempts — wait a moment";
            } else if (res === PamResult.Error) {
                root.errorText = "Authentication error";
            } else {
                root.errorText = "Wrong password";
            }
            root.failed();
            errReset.restart();
        }
    }

    Timer {
        id: errReset
        interval: 4000
        onTriggered: {
            root.errorText = "";
            root._maxed = false;
        }
    }

    // Unlock from elsewhere (IPC) — drop any half-typed state and abort a
    // pending attempt.
    Connections {
        target: LockController
        function onLockedChanged() {
            if (LockController.locked)
                return;
            root.buffer = "";
            root.errorText = "";
            root._maxed = false;
            pam.abort();
        }
    }

    // --- auto-lock ------------------------------------------------------
    // Replaces swayidle: lock after LockConfig.idleTimeoutSec of no input.
    IdleMonitor {
        // Caffeine (`qs.services`) also holds a Wayland idle inhibitor, which
        // already suppresses idle notifications — the explicit check just makes
        // the intent obvious and covers compositors that notify anyway.
        enabled: LockConfig.idleLock && !LockController.locked && !Caffeine.active
        timeout: LockConfig.idleTimeoutSec
        onIsIdleChanged: if (isIdle) LockController.lock()
    }

    // Lock the moment logind announces an impending suspend, so the screen is
    // already covered when the machine wakes.
    Process {
        running: true
        command: ["dbus-monitor", "--system",
            "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"]
        stdout: SplitParser {
            onRead: line => {
                if (LockConfig.lockBeforeSleep && line.indexOf("boolean true") >= 0)
                    LockController.lock();
            }
        }
    }
}
