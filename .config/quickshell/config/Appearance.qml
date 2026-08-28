pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User-facing appearance config: the active colour scheme, UI fonts, wallpaper
// and profile picture. Persisted as JSON at ~/.config/quickshell/appearance.json
// (written by Settings > General). Colour schemes are plain JSON files in
// ~/.config/quickshell/colorschemes/ — the two built-ins are seeded there on
// first run so there's always an example to copy.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/quickshell"
    readonly property string schemesDir: dir + "/colorschemes"

    // --- persisted selections -------------------------------------------------
    readonly property string schemeName: adapter.scheme
    readonly property string fontFamily: adapter.fontFamily
    readonly property string fontMono: adapter.fontMono
    readonly property string wallpaper: adapter.wallpaper
    readonly property string avatar: adapter.avatar

    function setScheme(name)   { adapter.scheme = name; }
    function setFont(family)   { adapter.fontFamily = family; }
    function setMono(family)   { adapter.fontMono = family; }
    function setWallpaper(p)   { adapter.wallpaper = p; }
    function setAvatar(p)      { adapter.avatar = p; }

    // --- colour schemes -----------------------------------------------------
    // name -> { base, mantle, ... , blue, lavender }  (26 Catppuccin-style keys)
    property var schemes: ({})
    readonly property var schemeNames: Object.keys(schemes).sort()
    readonly property var palette: schemes[schemeName] ?? schemes["mocha"] ?? builtins.mocha

    readonly property var builtins: ({
        "mocha": {
            "base": "#1e1e2e", "mantle": "#181825", "crust": "#11111b",
            "surface0": "#313244", "surface1": "#45475a", "surface2": "#585b70",
            "overlay0": "#6c7086", "overlay1": "#7f849c", "overlay2": "#9399b2",
            "subtext0": "#a6adc8", "subtext1": "#bac2de", "text": "#cdd6f4",
            "rosewater": "#f5e0dc", "flamingo": "#f2cdcd", "pink": "#f5c2e7",
            "mauve": "#cba6f7", "red": "#f38ba8", "maroon": "#eba0ac",
            "peach": "#fab387", "yellow": "#f9e2af", "green": "#a6e3a1",
            "teal": "#94e2d5", "sky": "#89dceb", "sapphire": "#74c7ec",
            "blue": "#89b4fa", "lavender": "#b4befe"
        },
        "latte": {
            "base": "#eff1f5", "mantle": "#e6e9ef", "crust": "#dce0e8",
            "surface0": "#ccd0da", "surface1": "#bcc0cc", "surface2": "#acb0be",
            "overlay0": "#9ca0b0", "overlay1": "#8c8fa1", "overlay2": "#7c7f93",
            "subtext0": "#6c6f85", "subtext1": "#5c5f77", "text": "#4c4f69",
            "rosewater": "#dc8a78", "flamingo": "#dd7878", "pink": "#ea76cb",
            "mauve": "#8839ef", "red": "#d20f39", "maroon": "#e64553",
            "peach": "#fe640b", "yellow": "#df8e1d", "green": "#40a02b",
            "teal": "#179299", "sky": "#04a5e5", "sapphire": "#209fb5",
            "blue": "#1e66f5", "lavender": "#7287fd"
        }
    })

    function reloadSchemes() {
        schemeScan.running = true;
    }

    property var _seedQueue: []

    Component.onCompleted: {
        // start from the built-ins, then merge whatever's on disk
        schemes = JSON.parse(JSON.stringify(builtins));
        seedProc.running = true;
    }

    // list which built-in schemes are missing from the dir, then seed them
    Process {
        id: seedProc
        command: ["bash", "-c",
            'mkdir -p "$0" && ' +
            'for n in mocha latte; do [ -e "$0/$n.json" ] || echo "$n"; done',
            root.schemesDir]
        stdout: StdioCollector {
            onStreamFinished: {
                root._seedQueue = text.trim().split("\n").filter(n => n.length > 0);
                seedWriter.next();
            }
        }
    }

    // writes the queued built-ins one at a time (a single Process can't run
    // concurrent execs), then rescans
    Process {
        id: seedWriter
        function next() {
            if (root._seedQueue.length === 0) {
                root.reloadSchemes();
                return;
            }
            const name = root._seedQueue.shift();
            exec({
                "environment": {
                    "BODY": JSON.stringify(root.builtins[name], null, 2),
                    "F": root.schemesDir + "/" + name + ".json"
                },
                "command": ["bash", "-c", 'printf "%s\\n" "$BODY" > "$F"']
            });
        }
        onExited: next()
    }

    // cat every *.json in the schemes dir, tagged by basename
    Process {
        id: schemeScan
        command: ["bash", "-c",
            'for f in "$0"/*.json; do [ -e "$f" ] || continue; ' +
            'printf "\\x1e%s\\x1f" "$(basename "$f" .json)"; cat "$f"; done',
            root.schemesDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const merged = JSON.parse(JSON.stringify(root.builtins));
                for (const chunk of text.split("\x1e")) {
                    if (!chunk) continue;
                    const sep = chunk.indexOf("\x1f");
                    if (sep < 0) continue;
                    const name = chunk.slice(0, sep).trim();
                    const bodyText = chunk.slice(sep + 1).trim();
                    if (!name || !bodyText) continue;
                    try {
                        const body = JSON.parse(bodyText);
                        if (body && typeof body === "object" && body.base)
                            merged[name] = body;
                    } catch (e) {
                        console.warn("[Appearance] bad scheme", name, e);
                    }
                }
                root.schemes = merged;
            }
        }
    }

    FileView {
        id: file
        path: root.dir + "/appearance.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: adapter
            property string scheme: "mocha"
            property string fontFamily: "Rubik"
            property string fontMono: "Monaspace Neon NF"
            property string wallpaper: ""
            property string avatar: ""
        }
    }
}
