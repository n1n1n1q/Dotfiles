pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.services.niri

// Notification daemon + store.
//
// Wraps Quickshell's NotificationServer (the real org.freedesktop.Notifications
// D-Bus service - having this instantiated is what makes the shell *the*
// notification daemon) and keeps two views on top of it:
//
//   * `list`   - every notification we've kept, newest first. This is what the
//                dashboard's notification centre renders. Persisted to
//                Quickshell.dataPath so it survives a shell restart, though
//                entries restored from disk lose their live actions
//                (`entry.notification` is null for those).
//   * `popups` - the transient subset currently sliding in at the top-right.
//                NotificationPopups times these out; dismissing a popup leaves
//                the entry in `list`.
//
// `doNotDisturb` suppresses popups only - the centre still records everything.
Singleton {
    id: root

    // Entry shape: { key, notification|null, appName, summary, body, appIcon,
    //                image, critical, low, time }
    property var list: []
    property var popups: []
    property bool doNotDisturb: false
    property int _seq: 1

    readonly property int count: list.length

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

            const entry = {
                key: root._seq++,
                notification: notification,
                appName: notification.appName || "Notification",
                desktopEntry: notification.desktopEntry || "",
                summary: notification.summary,
                body: notification.body,
                appIcon: notification.appIcon,
                image: notification.image,
                critical: notification.urgency === NotificationUrgency.Critical,
                low: notification.urgency === NotificationUrgency.Low,
                time: Date.now()
            }

            // Cap the centre at 100; untrack anything that falls off the end so
            // the server doesn't hold pixmaps forever.
            const full = [entry, ...root.list]
            for (const e of full.slice(100))
                if (e.notification) e.notification.tracked = false
            root.list = full.slice(0, 100)
            root._save()

            if (!root.doNotDisturb)
                root.popups = [entry, ...root.popups]

            notification.closed.connect(() => root._forget(entry))
        }
    }

    // The app (or the server) closed this notification out from under us.
    function _forget(entry) {
        root.popups = root.popups.filter(e => e !== entry)
        root.list = root.list.filter(e => e !== entry)
        root._save()
    }

    // Popup timed out / was swiped away - stop the toast, keep it in the centre.
    function dismissPopup(entry) {
        root.popups = root.popups.filter(e => e !== entry)
    }

    // Clicked the notification body: jump to the app that sent it. Returns
    // whether a window was found to focus.
    function activate(entry) {
        return NiriService.focusApp(entry.desktopEntry)
            || NiriService.focusApp(entry.appName)
    }

    // Removed from the centre - drop it and tell the app we're done.
    function dismiss(entry) {
        root.popups = root.popups.filter(e => e !== entry)
        root.list = root.list.filter(e => e !== entry)
        if (entry.notification) {
            entry.notification.tracked = false
            entry.notification.dismiss()
        }
        root._save()
    }

    function clear() {
        for (const e of root.list) {
            if (e.notification) {
                e.notification.tracked = false
                e.notification.dismiss()
            }
        }
        root.list = []
        root.popups = []
        root._save()
    }

    function toggleDnd() {
        root.doNotDisturb = !root.doNotDisturb
        if (root.doNotDisturb) root.popups = []
    }

    // `qs ipc call notifications dnd|dndOn|dndOff` — handy for a niri keybind.
    IpcHandler {
        target: "notifications"
        function dnd(): void { root.toggleDnd() }
        function dndOn(): void { root.doNotDisturb = true; root.popups = [] }
        function dndOff(): void { root.doNotDisturb = false }
        function clear(): void { root.clear() }
    }

    // --- helpers used by the card ---------------------------------------

    function iconSource(entry) {
        // `image` (raw pixmap hint) and path-shaped `appIcon`s are usable as an
        // Image source as-is; a bare name goes through the icon theme.
        if (entry.image) return entry.image
        if (!entry.appIcon) return ""
        if (entry.appIcon.startsWith("/") || entry.appIcon.startsWith("file:"))
            return entry.appIcon
        return Quickshell.iconPath(entry.appIcon, "")
    }

    function timeText(ts) {
        const d = Math.floor((Date.now() - ts) / 1000)
        if (d < 60) return "now"
        if (d < 3600) return Math.floor(d / 60) + "m ago"
        if (d < 86400) return Math.floor(d / 3600) + "h ago"
        return Math.floor(d / 86400) + "d ago"
    }

    // --- persistence ---------------------------------------------------

    function _save() {
        const plain = root.list.map(e => ({
            appName: e.appName, desktopEntry: e.desktopEntry,
            summary: e.summary, body: e.body,
            appIcon: e.appIcon, image: e.image,
            critical: e.critical, low: e.low, time: e.time
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
                const restored = saved.map(e => ({
                    key: root._seq++,
                    notification: null,
                    appName: e.appName || "Notification",
                    desktopEntry: e.desktopEntry || "",
                    summary: e.summary || "",
                    body: e.body || "",
                    appIcon: e.appIcon || "",
                    image: e.image || "",
                    critical: !!e.critical,
                    low: !!e.low,
                    time: e.time || Date.now()
                }))
                // Live notifications that already arrived win the top slots.
                root.list = [...root.list, ...restored].slice(0, 100)
            } catch (err) {
                // Corrupt or empty store - start clean.
            }
        }
    }
}
