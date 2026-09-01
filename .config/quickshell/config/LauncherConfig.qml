pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The app launcher (modules/launcher): how many results it shows, and what it
// does with a query that isn't an app.
//
//   {
//     "maxResults": 10,
//     "frecency": true,
//     "showExtras": true,
//     "terminal": "alacritty",
//     "webSearchUrl": "https://duckduckgo.com/?q=",
//     "prefixes": { "command": ">", "math": "=", "web": "?" }
//   }
//
// Persisted as JSON at ~/.config/quickshell/launcher.json — hand-editable, and
// written back by Settings > Launcher. The prefix characters are only settable
// here, in the file; everything else has a control on the page.
Singleton {
    id: root

    readonly property int maxResults: adapter.maxResults
    readonly property bool frecency: adapter.frecency
    readonly property bool showExtras: adapter.showExtras
    readonly property string terminal: adapter.terminal
    readonly property string webSearchUrl: adapter.webSearchUrl

    function setMaxResults(n) { adapter.maxResults = Math.max(3, Math.min(30, n)); }
    function setFrecency(v)   { adapter.frecency = v; }
    function setShowExtras(v) { adapter.showExtras = v; }
    function setTerminal(t)   { adapter.terminal = t; }
    function setWebSearchUrl(u) { adapter.webSearchUrl = u; }

    // --- the non-app modes --------------------------------------------------
    // A query opening with one of these characters is *only* that mode — the
    // apps drop out entirely, which is the point of typing the prefix. Without
    // one, apps come first and these trail behind them (`showExtras`), so the
    // prefixes are a way to skip straight to the bottom of the list rather
    // than the only way to reach it.
    readonly property var modes: [
        {
            id: "command", prefix: adapter.prefixes?.command ?? ">",
            name: "Command", icon: "󰆍", verb: "Run",
            desc: "Hand the rest of the line to bash"
        },
        {
            id: "math", prefix: adapter.prefixes?.math ?? "=",
            name: "Math", icon: "󰪚", verb: "Copy",
            desc: "Evaluate it and copy the answer"
        },
        {
            id: "web", prefix: adapter.prefixes?.web ?? "?",
            name: "Web search", icon: "󰖟", verb: "Search",
            desc: "Open the search engine below with the rest of the line"
        }
    ]

    // The mode a query has been forced into, or null for a plain app search.
    function modeFor(query) {
        for (const m of modes)
            if (m.prefix.length > 0 && query.startsWith(m.prefix))
                return m;
        return null;
    }
    function modeById(id) { return modes.find(m => m.id === id) ?? null; }
    function prefixOf(id) { return modeById(id)?.prefix ?? ""; }

    // --- pickers ------------------------------------------------------------
    // Offered in Settings; anything else is still legal in the file, and shows
    // there as the combo's fallback text.
    readonly property var engines: [
        { name: "DuckDuckGo", url: "https://duckduckgo.com/?q=" },
        { name: "Google",     url: "https://www.google.com/search?q=" },
        { name: "Bing",       url: "https://www.bing.com/search?q=" },
        { name: "Brave",      url: "https://search.brave.com/search?q=" },
        { name: "Kagi",       url: "https://kagi.com/search?q=" },
        { name: "Startpage",  url: "https://www.startpage.com/sp/search?query=" },
        { name: "Wikipedia",  url: "https://en.wikipedia.org/w/index.php?search=" }
    ]
    readonly property string engineName:
        engines.find(e => e.url === webSearchUrl)?.name ?? webSearchUrl

    readonly property var terminals: [
        "alacritty", "kitty", "foot", "ghostty", "wezterm",
        "gnome-terminal", "konsole", "xterm"
    ]

    // --- defaults -----------------------------------------------------------
    readonly property var defaults: ({
        "maxResults": 10,
        "frecency": true,
        "showExtras": true,
        "terminal": "alacritty",
        "webSearchUrl": "https://duckduckgo.com/?q=",
        "prefixes": { "command": ">", "math": "=", "web": "?" }
    })

    function reset() {
        adapter.maxResults = defaults.maxResults;
        adapter.frecency = defaults.frecency;
        adapter.showExtras = defaults.showExtras;
        adapter.terminal = defaults.terminal;
        adapter.webSearchUrl = defaults.webSearchUrl;
        adapter.prefixes = JSON.parse(JSON.stringify(defaults.prefixes));
    }

    // --- preset slice -------------------------------------------------------
    function snapshot() {
        return JSON.parse(JSON.stringify({
            "maxResults": adapter.maxResults,
            "frecency": adapter.frecency,
            "showExtras": adapter.showExtras,
            "terminal": adapter.terminal,
            "webSearchUrl": adapter.webSearchUrl,
            "prefixes": adapter.prefixes ?? defaults.prefixes
        }));
    }

    function applySnapshot(o) {
        if (!o) return;
        if (o.maxResults !== undefined) adapter.maxResults = o.maxResults;
        if (o.frecency !== undefined) adapter.frecency = o.frecency;
        if (o.showExtras !== undefined) adapter.showExtras = o.showExtras;
        if (o.terminal !== undefined) adapter.terminal = o.terminal;
        if (o.webSearchUrl !== undefined) adapter.webSearchUrl = o.webSearchUrl;
        if (o.prefixes)
            adapter.prefixes = Object.assign(
                JSON.parse(JSON.stringify(defaults.prefixes)), o.prefixes);
    }

    // There is one launcher per screen, so opening it goes through these
    // signals — every live LauncherWindow listens and takes the ones addressed
    // to it. An empty `screenName` means "wherever the pointer is".
    signal showRequested(string screenName)
    signal hideRequested(string screenName)
    signal toggleRequested(string screenName)
    // Open pre-filled. A keybind can land you straight in one of the modes by
    // passing nothing but its prefix.
    signal searchRequested(string text)

    function requestShow(s) { showRequested(s ?? ""); }
    function requestHide(s) { hideRequested(s ?? ""); }
    function requestToggle(s) { toggleRequested(s ?? ""); }
    function requestSearch(t) { searchRequested(t ?? ""); }

    // Drives the launcher from a niri keybind:
    //   qs ipc call launcher toggle
    IpcHandler {
        target: "launcher"
        // `open`, not `show`: `show` is one of `qs ipc`'s own subcommands and
        // the CLI swallows it before it reaches the handler.
        function open(): void { root.requestShow(""); }
        function hide(): void { root.requestHide(""); }
        function toggle(): void { root.requestToggle(""); }
        // qs ipc call launcher search ">"   opens it in command mode
        function search(text: string): void { root.requestSearch(text); }
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/launcher.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: adapter
            property int maxResults: root.defaults.maxResults
            property bool frecency: root.defaults.frecency
            property bool showExtras: root.defaults.showExtras
            property string terminal: root.defaults.terminal
            property string webSearchUrl: root.defaults.webSearchUrl
            property var prefixes: root.defaults.prefixes
        }
    }
}
