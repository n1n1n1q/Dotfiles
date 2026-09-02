pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Lock-screen behaviour: whether to auto-lock on idle / before sleep, and what
// the lock surface shows. Persisted as JSON at ~/.config/quickshell/lock.json
// (edited in Settings › Lock screen). The lock itself lives in modules/lock;
// the idle / sleep watching in services/IdleService.
Singleton {
    id: root

    readonly property bool idleLock: adapter.idleLock
    readonly property int idleTimeoutSec: adapter.idleTimeoutSec
    readonly property bool lockBeforeSleep: adapter.lockBeforeSleep
    readonly property bool showMedia: adapter.showMedia

    function setIdleLock(v)      { adapter.idleLock = v; }
    function setIdleTimeout(sec) { adapter.idleTimeoutSec = Math.max(15, Math.round(sec)); }
    function setLockBeforeSleep(v) { adapter.lockBeforeSleep = v; }
    function setShowMedia(v)     { adapter.showMedia = v; }

    // --- preset slice -----------------------------------------------------
    function snapshot() {
        return {
            "idleLock": adapter.idleLock,
            "idleTimeoutSec": adapter.idleTimeoutSec,
            "lockBeforeSleep": adapter.lockBeforeSleep,
            "showMedia": adapter.showMedia
        };
    }
    function applySnapshot(o) {
        if (!o) return;
        if (o.idleLock !== undefined) adapter.idleLock = o.idleLock;
        if (o.idleTimeoutSec !== undefined) adapter.idleTimeoutSec = o.idleTimeoutSec;
        if (o.lockBeforeSleep !== undefined) adapter.lockBeforeSleep = o.lockBeforeSleep;
        if (o.showMedia !== undefined) adapter.showMedia = o.showMedia;
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/lock.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: adapter
            property bool idleLock: true
            property int idleTimeoutSec: 300
            property bool lockBeforeSleep: true
            property bool showMedia: true
        }
    }
}
