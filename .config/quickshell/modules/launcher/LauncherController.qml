pragma Singleton

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.services.niri
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
    readonly property string term:
        (mode ? query.slice(mode.prefix.length) : query).trim()

    readonly property var apps:
        mode ? [] : Apps.query(term, LauncherConfig.maxResults)

    readonly property var results: {
        const q = root.term;

        // A prefix means "only this" — the whole point of typing one is to
        // stop the apps from crowding out what you're actually after.
        if (root.mode) {
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
            "run": () => Apps.launch(entry, action)
        };
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
