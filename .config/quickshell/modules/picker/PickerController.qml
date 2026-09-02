pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.services.niri

// State for the wallpaper / colour-scheme picker — a full-screen carousel you
// step through left→right, applying each one live as you land on it. The
// windows are per-output (see PickerLayer); only one is ever open, so the
// selection lives here.
//
// Live-applies through the *silent* setters (Wallpaper.select /
// Appearance.setScheme), never the stepped ones — the carousel is its own
// feedback, so it must not also fire the OSD pill.
//
//   qs ipc call picker wallpaper
//   qs ipc call picker theme
Singleton {
    id: root

    // Output the picker is up on; "" means closed.
    property string openOn: ""
    readonly property bool open: openOn.length > 0

    // "wallpaper" | "theme"
    property string kind: "wallpaper"

    // What was active when the picker opened, per kind — `cancel()` puts both
    // back, so toggling kind mid-browse and then backing out is lossless.
    property string _origWallpaper: ""
    property string _origScheme: ""

    readonly property var items:
        kind === "theme" ? Appearance.schemeNames : Wallpaper.wallpapers

    // Where the live value sits in `items` right now.
    readonly property int liveIndex:
        kind === "theme"
            ? Appearance.schemeNames.indexOf(Appearance.schemeName)
            : Wallpaper.wallpapers.indexOf(Wallpaper.current)

    // Carousel position. Kept in sync with the live value while browsing; a
    // separate property so it survives `items` churning underneath it.
    property int index: 0

    function _apply(i) {
        const list = root.items;
        if (i < 0 || i >= list.length)
            return;
        if (root.kind === "theme")
            Appearance.setScheme(list[i]);
        else
            Wallpaper.select(list[i]);
    }

    function step(delta) {
        const n = root.items.length;
        if (n === 0)
            return;
        root.index = ((root.index + delta) % n + n) % n;
        root._apply(root.index);
    }

    function randomize() {
        const n = root.items.length;
        if (n <= 1) {
            if (n === 1) { root.index = 0; root._apply(0); }
            return;
        }
        let i = root.index;
        while (i === root.index)
            i = Math.floor(Math.random() * n);
        root.index = i;
        root._apply(i);
    }

    function setKind(k) {
        if (k !== "wallpaper" && k !== "theme")
            return;
        root.kind = k;
        // Land on whatever is currently active for the new kind.
        root.index = Math.max(0, root.liveIndex);
    }

    // --- opening / closing -------------------------------------------------
    function show(k, screenName) {
        root._origWallpaper = Wallpaper.current;
        root._origScheme = Appearance.schemeName;
        root.setKind(k && k.length > 0 ? k : "wallpaper");
        root.openOn = (screenName && screenName.length > 0)
            ? screenName : _preferredScreen();
    }
    function hide() { root.openOn = ""; }
    function toggle(k, screenName) {
        if (root.open)
            root.hide();
        else
            root.show(k, screenName);
    }

    // Keep the browsed selection.
    function confirm() { root.hide(); }

    // Put back what was active when the picker opened.
    function cancel() {
        if (root._origScheme.length > 0 && root._origScheme !== Appearance.schemeName)
            Appearance.setScheme(root._origScheme);
        if (root._origWallpaper !== Wallpaper.current)
            Wallpaper.select(root._origWallpaper);
        root.hide();
    }

    function _preferredScreen() {
        const focused = NiriService.focusedWorkspace?.output ?? "";
        if (focused.length > 0)
            return focused;
        return Quickshell.screens[0]?.name ?? "";
    }

    IpcHandler {
        target: "picker"

        function wallpaper(): void { root.show("wallpaper", ""); }
        function theme(): void { root.show("theme", ""); }
        function toggle(kind: string): void { root.toggle(kind, ""); }
        function random(): void {
            if (!root.open) root.show("wallpaper", "");
            root.randomize();
        }
        function close(): void { root.cancel(); }
    }
}
