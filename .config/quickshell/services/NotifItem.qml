pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.services

// One notification, as a live object rather than a plain record. Owning its own
// state is what makes deletion reliable: the list views bind to stable object
// instances (via a ScriptModel), so a new notification arriving — or another
// card being dismissed — never rebuilds the delegate that is mid-animation.
//
// Removal is a two-step handshake with the card:
//   1. something calls close() — the item goes `closed` but stays in the list
//      as long as any card still holds a lock on it (it is animating out)
//   2. the card's exit animation finishes, it unlock()s, and the last unlock
//      runs the real removal: drop from Notifications.list, tell the server,
//      destroy the object.
QtObject {
    id: item

    // Set by Notifications when it creates the object.
    property var notification: null
    property int key: 0
    property bool popup: false
    property bool closed: false
    property bool _dead: false
    property bool _serverClosed: false

    property string appName: "Notification"
    property string desktopEntry: ""
    property string summary: ""
    property string body: ""
    property string appIcon: ""
    property string image: ""
    property bool critical: false
    property bool low: false
    property date time: new Date()
    property list<var> actions: []

    // Cards that are currently mounted on this item. While the set is non-empty
    // a close() only marks `closed`; the real removal waits for the last card
    // to release (after its exit animation).
    property var locks: new Set()

    // "now" / "5m" / "2h" / "3d", refreshed on a timer that widens its own
    // interval as the notification ages.
    property string timeStr: "now"

    readonly property Timer _timeTimer: Timer {
        running: !item.closed
        repeat: true
        triggeredOnStart: true
        interval: 30000
        onTriggered: item._updateTimeStr()
    }

    function _updateTimeStr() {
        const m = Math.floor((Date.now() - item.time.getTime()) / 60000);
        if (m < 1) { item.timeStr = "now"; _timeTimer.interval = 30000; return; }
        const h = Math.floor(m / 60);
        const d = Math.floor(h / 24);
        if (d > 0) { item.timeStr = d + "d"; _timeTimer.interval = 3600000; }
        else if (h > 0) { item.timeStr = h + "h"; _timeTimer.interval = 300000; }
        else { item.timeStr = m + "m"; _timeTimer.interval = m < 10 ? 30000 : 60000; }
    }

    // Keep the live props in sync while the notification is still open, and
    // fold a server-side close into our own removal path.
    readonly property Connections _conn: Connections {
        target: item.notification
        enabled: item.notification !== null

        function onClosed() { item._serverClosed = true; item.close(); }
        function onSummaryChanged() { item.summary = item.notification.summary; }
        function onBodyChanged() { item.body = item.notification.body; }
        function onAppIconChanged() { item.appIcon = item.notification.appIcon; }
        function onAppNameChanged() { item.appName = item.notification.appName || "Notification"; }
        function onImageChanged() { item.image = item.notification.image; }
        function onUrgencyChanged() {
            item.critical = item.notification.urgency === NotificationUrgency.Critical;
            item.low = item.notification.urgency === NotificationUrgency.Low;
        }
        function onActionsChanged() { item.actions = item._readActions(); }
    }

    function _readActions() {
        if (!notification || !notification.actions)
            return [];
        return notification.actions.map(a => ({
            identifier: a.identifier,
            text: a.text,
            invoke: () => a.invoke()
        }));
    }

    function lock(who) { locks.add(who); }
    function unlock(who) {
        locks.delete(who);
        if (closed)
            close();
    }

    // Drop the toast but keep the entry in the centre.
    function dropPopup() { popup = false; }

    function close() {
        closed = true;
        // Wait for the last card to release; never run the teardown twice
        // (notification.dismiss() trips our own onClosed).
        if (locks.size > 0 || _dead)
            return;
        _dead = true;
        Notifications._remove(item);
        if (notification && !_serverClosed) {
            try { notification.dismiss(); } catch (e) {}
        }
        item.destroy();
    }

    Component.onCompleted: {
        if (!notification)
            return;
        key = notification.id;
        appName = notification.appName || "Notification";
        desktopEntry = notification.desktopEntry || "";
        summary = notification.summary;
        body = notification.body;
        appIcon = notification.appIcon;
        image = notification.image;
        critical = notification.urgency === NotificationUrgency.Critical;
        low = notification.urgency === NotificationUrgency.Low;
        actions = _readActions();
    }
}
