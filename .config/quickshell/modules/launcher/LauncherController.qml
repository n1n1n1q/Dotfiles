pragma Singleton

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.services.niri
import qs.modules.picker
import qs.modules.settings
import "calc.js" as Calc

// What the launcher is currently searching for, and what it found.
//
// Only one launcher is on screen at a time (the windows are per-output, but
// opening one closes the rest), so the query and the selection live here
// rather than in the window — which also means the result list is built once
// per keystroke no matter how many monitors are plugged in.
//
// A result is a plain object, deliberately: { kind, name, sub, type, verb,
// icon, glyph, mono, run }. `icon` is a themed image path and `glyph` a Nerd
// Font character — a row draws whichever one it was given — and `run` is the
// closure that actually does the thing.
Singleton {
    id: root

    // Name of the output the launcher is currently up on; empty means closed.
    // Keeping it here rather than per-window is what stops two of them
    // grabbing the keyboard at once on a multi-head setup.
    property string openOn: ""
    readonly property bool open: openOn.length > 0

    property string query: ""
    property int selected: 0

    // The mode the query's opening character forced it into, or null for the
    // ordinary app search.
    readonly property var mode: LauncherConfig.modeFor(query)
    // Pull a fresh clipboard list the moment the query enters that mode.
    onModeChanged: if (mode && mode.id === "clipboard") Clipboard.refresh()
    readonly property string term:
        (mode ? query.slice(mode.prefix.length) : query).trim()

    readonly property var apps:
        mode ? [] : Apps.query(term, LauncherConfig.maxResults)

    readonly property var results: {
        const q = root.term;

        // A prefix means "only this" — the whole point of typing one is to
        // stop the apps from crowding out what you're actually after.
        if (root.mode) {
            if (root.mode.list)
                return root._listMode(root.mode.id, q);
            const only = root._extra(root.mode.id, q);
            return only ? [only] : [];
        }

        const out = root.apps.map(a => root._appResult(a));

        // With no query there is nothing for the extras to act on; the app
        // list is standing in for a "frequently used" panel.
        if (q.length === 0 || !LauncherConfig.showExtras)
            return out;

        // A sum goes to the top rather than the bottom: if the line reads as
        // arithmetic, the answer is what was wanted, not an app that happens
        // to share a letter with it.
        const math = Calc.looksLikeMath(q) ? root._extra("math", q) : null;
        if (math)
            out.unshift(math);

        const command = root._extra("command", q);
        if (command)
            out.push(command);

        const web = root._extra("web", q);
        if (web)
            out.push(web);

        for (const a of root._actions(q))
            out.push(a);

        return out;
    }

    readonly property int count: results.length
    readonly property var current: results[selected] ?? null

    // --- building results ---------------------------------------------------
    function _appResult(hit) {
        const entry = hit.entry;
        const action = hit.action;
        return {
            "kind": action ? "action" : "app",
            "name": action ? action.name : entry.name,
            "sub": action ? entry.name
                : (entry.genericName || entry.comment || ""),
            "type": action ? "Action" : "App",
            "verb": "Open",
            "icon": Apps.iconSource(action && action.icon ? action : entry),
            "glyph": "",
            "mono": false,
            "favorite": !action && LauncherConfig.isFavorite(entry.id),
            "appId": action ? "" : (entry.id ?? ""),
            "run": () => Apps.launch(entry, action)
        };
    }

    // --- wallpaper / theme list modes -------------------------------------
    // The `;w` / `;t` prefixes list the folder / the installed schemes as rows
    // you apply straight from the launcher, cover art / swatch and all.
    function _listMode(id, q) {
        const needle = q.toLowerCase();
        const cap = LauncherConfig.maxResults;

        if (id === "wallpaper") {
            return Wallpaper.wallpapers
                .map(p => ({ path: p,
                             base: p.split("/").pop().replace(/\.[^.]+$/, "") }))
                .filter(w => needle.length === 0
                    || w.base.toLowerCase().includes(needle))
                .slice(0, cap)
                .map(w => ({
                    "kind": "wallpaper", "name": w.base,
                    "sub": w.path === Wallpaper.current ? "Current" : "",
                    "type": "Wallpaper", "verb": "Apply",
                    "icon": w.path, "glyph": "", "mono": false,
                    "run": () => Wallpaper.select(w.path)
                }));
        }

        if (id === "theme") {
            return Appearance.schemeNames
                .filter(n => needle.length === 0
                    || n.toLowerCase().includes(needle))
                .slice(0, cap)
                .map(n => ({
                    "kind": "theme",
                    "name": n.charAt(0).toUpperCase() + n.slice(1),
                    "sub": n === Appearance.schemeName ? "Current" : "",
                    "type": "Theme", "verb": "Apply",
                    "icon": "", "glyph": "", "mono": false,
                    "swatch": ["red", "peach", "green", "blue", "mauve"]
                        .map(k => (Appearance.schemes[n] ?? {})[k] ?? "#888888"),
                    "run": () => Appearance.setScheme(n)
                }));
        }

        if (id === "clipboard") {
            if (!Clipboard.available)
                return [{
                    "kind": "info", "name": "Clipboard history needs cliphist",
                    "sub": "Install cliphist + wl-clipboard, then reopen",
                    "type": "Clipboard", "verb": "",
                    "icon": "", "glyph": "󰅍", "mono": false,
                    "run": () => {}
                }];
            return Clipboard.entries
                .filter(e => needle.length === 0
                    || e.preview.toLowerCase().includes(needle))
                .slice(0, cap)
                .map(e => ({
                    "kind": "clipboard",
                    "name": e.isImage ? "Image" : e.preview,
                    "sub": e.isImage ? e.preview : "",
                    "type": "Clipboard", "verb": "Copy",
                    "icon": "", "glyph": e.isImage ? "󰋩" : "󰅍",
                    "mono": !e.isImage,
                    "run": () => Clipboard.copy(e)
                }));
        }

        return [];
    }

    // --- shell action rows -----------------------------------------------
    // Appended after the app list (like the command / web extras) when the
    // query brushes past one of their keywords — a way to reach the pickers
    // and Settings without leaving the launcher.
    function _actions(q) {
        const s = q.toLowerCase();
        const out = [];
        const add = (name, sub, glyph, run) => out.push({
            "kind": "action", "name": name, "sub": sub,
            "type": "Shell", "verb": "Open",
            "icon": "", "glyph": glyph, "mono": false, "run": run
        });

        if (/wall|bg|background/.test(s))
            add("Wallpaper picker", "Browse and set the wallpaper", "󰸉",
                () => PickerController.show("wallpaper", ""));
        if (/theme|scheme|colou?r/.test(s))
            add("Theme picker", "Browse and switch the colour scheme", "󰏘",
                () => PickerController.show("theme", ""));
        if (/random|shuffle|wall|bg/.test(s))
            add("Random wallpaper", "Jump to a random one", "󰒟",
                () => Wallpaper.random());
        if (/settings|preferences|config|control/.test(s))
            add("Settings", "Open the settings window", "󰒓",
                () => SettingsController.show());

        return out;
    }

    // One of the three non-app modes, or null when there's nothing to show —
    // an expression that doesn't parse has no math row, and an empty line has
    // nothing to run or search for.
    function _extra(id, q) {
        const m = LauncherConfig.modeById(id);
        if (!m || q.length === 0)
            return null;

        if (id === "math") {
            const r = Calc.evaluate(q);
            if (!r.ok)
                return null;
            return {
                "kind": "math", "name": r.text, "sub": q,
                "type": m.name, "verb": m.verb,
                "icon": "", "glyph": m.icon, "mono": true,
                "run": () => { Quickshell.clipboardText = r.text; }
            };
        }

        if (id === "command") {
            return {
                "kind": "command", "name": q, "sub": "Run with bash",
                "type": m.name, "verb": m.verb,
                "icon": "", "glyph": m.icon, "mono": true,
                "run": () => Quickshell.execDetached(["bash", "-c", q])
            };
        }

        return {
            "kind": "web", "name": q, "sub": LauncherConfig.engineName,
            "type": m.name, "verb": m.verb,
            "icon": "", "glyph": m.icon, "mono": false,
            "run": () => Qt.openUrlExternally(
                LauncherConfig.webSearchUrl + encodeURIComponent(q))
        };
    }

    // --- driving it ---------------------------------------------------------
    onQueryChanged: selected = 0

    // The list can shrink under the selection when a result stops matching
    // (an app opened from another launcher, a sum that stopped parsing).
    onCountChanged: if (selected >= count) selected = Math.max(0, count - 1)

    function move(delta) {
        if (count === 0)
            return;
        selected = ((selected + delta) % count + count) % count;
    }

    // Out of the way first: half of these open a window, and the launcher
    // sitting over it while it maps looks like the launch didn't take.
    function activate(index) {
        const r = results[index ?? selected] ?? null;
        if (!r)
            return false;
        hide();
        r.run();
        return true;
    }

    function reset() {
        query = "";
        selected = 0;
    }

    // --- opening and closing ------------------------------------------------
    function show(screenName) {
        reset();
        openOn = (screenName && screenName.length > 0)
            ? screenName : _preferredScreen();
    }
    function hide() { openOn = ""; }
    function toggle(screenName) {
        if (open)
            hide();
        else
            show(screenName);
    }

    // Where an unaddressed request lands: the output niri is focused on, so
    // the launcher opens under the eyes that asked for it. Falls back to the
    // first screen if niri hasn't answered yet.
    function _preferredScreen() {
        const focused = NiriService.focusedWorkspace?.output ?? "";
        if (focused.length > 0)
            return focused;
        return Quickshell.screens[0]?.name ?? "";
    }

    // Driven from a keybind through LauncherConfig's IPC handler:
    //   qs ipc call launcher toggle
    Connections {
        target: LauncherConfig
        function onShowRequested(screenName) { root.show(screenName); }
        function onHideRequested(screenName) { root.hide(); }
        function onToggleRequested(screenName) { root.toggle(screenName); }
        function onSearchRequested(text) {
            root.show("");
            root.query = text;
        }
    }

    // Swap whatever prefix the query carries for this one, so the mode buttons
    // in the search bar retarget a half-typed line instead of clearing it.
    function setMode(id) {
        const m = LauncherConfig.modeById(id);
        query = (m ? m.prefix : "") + term;
    }
}
