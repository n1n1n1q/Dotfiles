pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.services.niri

// Notification daemon + store.
//
// Instantiating NotificationServer here is what makes the shell *the*
// org.freedesktop.Notifications D-Bus service — no other daemon (dunst / mako /
// swaync) may be running or the name grab fails silently.
//
// Every notification is a `NotifItem` object (see NotifItem.qml), not a plain
// record. The views bind to those object instances through a ScriptModel, so
// adding or removing one never rebuilds the delegates around it — which is
// what makes the swipe-out animations reliable. `list` is the whole history
// (newest first, capped at 100); `popups` is the toast subset.
Singleton {
    id: root

    // NotifItem objects, newest first. Includes entries that are `closed` but
    // still animating out — a card holds a lock until its exit finishes.
    property var list: []

    readonly property var popups: root.list.filter(n => n.popup && !n.closed)
    readonly property int count: root.list.filter(n => !n.closed).length
    property bool doNotDisturb: false
    property int _seq: 1

    Component { id: itemComp; NotifItem {} }

    // Called by a NotifItem's own close() once its locks clear.
    function _remove(item) {
        root.list = root.list.filter(n => n !== item);
        _save();
    }

    NotificationServer {
        id: server
        keepOnReload: false

        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true

            const item = itemComp.createObject(root, {
                notification: notification,
                key: root._seq++,
                popup: !root.doNotDisturb,
                time: new Date()
            })

            root.list = [item, ...root.list]
            // Cap the history — close out anything past 100 (close() respects a
            // card that might still be holding it).
            const overflow = root.list.slice(100)
            root.list = root.list.slice(0, 100)
            for (const e of overflow)
                e.close()
            _save()
        }
    }

    // Clicked the body: focus the app that sent it. Returns whether a window
    // was found.
    function activate(item) {
        return NiriService.focusApp(item.desktopEntry)
            || NiriService.focusApp(item.appName)
    }

    function clearAll() {
        for (const item of root.list.slice())
            if (!item.closed)
                item.close()
    }

    function toggleDnd() {
        root.doNotDisturb = !root.doNotDisturb
        if (root.doNotDisturb)
            for (const item of root.list)
                item.popup = false
    }

    IpcHandler {
        target: "notifications"
        function dnd(): void { root.toggleDnd() }
        function dndOn(): void { root.doNotDisturb = true; for (const i of root.list) i.popup = false }
        function dndOff(): void { root.doNotDisturb = false }
        function clear(): void { root.clearAll() }
    }

    // --- helpers used by the card --------------------------------------

    function iconSource(item) {
        if (!item) return ""
        if (item.image) return item.image
        if (!item.appIcon) return ""
        if (item.appIcon.startsWith("/") || item.appIcon.startsWith("file:"))
            return item.appIcon
        return Quickshell.iconPath(item.appIcon, "")
    }

    // --- persistence -------------------------------------------------

    function _save() {
        const plain = root.list.filter(n => !n.closed).map(n => ({
            appName: n.appName, desktopEntry: n.desktopEntry,
            summary: n.summary, body: n.body,
            appIcon: n.appIcon, image: n.image,
            critical: n.critical, low: n.low, time: n.time.getTime()
        }))
        store.setText(JSON.stringify(plain))
    }

    FileView {
        id: store
        path: Quickshell.dataPath("notifications.json")
        printErrors: false

        onLoaded: {
            try {
                const saved = JSON.parse(store.text())
                if (!Array.isArray(saved) || saved.length === 0) return
                const restored = saved.map(e => itemComp.createObject(root, {
                    notification: null,
                    key: root._seq++,
                    popup: false,
                    appName: e.appName || "Notification",
                    desktopEntry: e.desktopEntry || "",
                    summary: e.summary || "",
                    body: e.body || "",
                    appIcon: e.appIcon || "",
                    image: e.image || "",
                    critical: !!e.critical,
                    low: !!e.low,
                    time: new Date(e.time || Date.now())
                }))
                // Live notifications that already arrived keep the top slots.
                root.list = [...root.list, ...restored].slice(0, 100)
            } catch (err) {
                // Corrupt or empty store — start clean.
            }
        }
    }
}
