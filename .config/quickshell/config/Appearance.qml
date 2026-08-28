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
        },
        "frappe": {
            "base": "#303446", "mantle": "#292c3c", "crust": "#232634",
            "surface0": "#414559", "surface1": "#51576d", "surface2": "#626880",
            "overlay0": "#737994", "overlay1": "#838ba7", "overlay2": "#949cbb",
            "subtext0": "#a5adce", "subtext1": "#b5bfe2", "text": "#c6d0f5",
            "rosewater": "#f2d5cf", "flamingo": "#eebebe", "pink": "#f4b8e4",
            "mauve": "#ca9ee6", "red": "#e78284", "maroon": "#ea999c",
            "peach": "#ef9f76", "yellow": "#e5c890", "green": "#a6d189",
            "teal": "#81c8be", "sky": "#99d1db", "sapphire": "#85c1dc",
            "blue": "#8caaee", "lavender": "#babbf1"
        },
        "macchiato": {
            "base": "#24273a", "mantle": "#1e2030", "crust": "#181926",
            "surface0": "#363a4f", "surface1": "#494d64", "surface2": "#5b6078",
            "overlay0": "#6e738d", "overlay1": "#8087a2", "overlay2": "#939ab7",
            "subtext0": "#a5adcb", "subtext1": "#b8c0e0", "text": "#cad3f5",
            "rosewater": "#f4dbd6", "flamingo": "#f0c6c6", "pink": "#f5bde6",
            "mauve": "#c6a0f6", "red": "#ed8796", "maroon": "#ee99a0",
            "peach": "#f5a97f", "yellow": "#eed49f", "green": "#a6da95",
            "teal": "#8bd5ca", "sky": "#91d7e3", "sapphire": "#7dc4e4",
            "blue": "#8aadf4", "lavender": "#b7bdf8"
        },
        "gruvbox": {
            "base": "#282828", "mantle": "#1d2021", "crust": "#1b1b1b",
            "surface0": "#3c3836", "surface1": "#504945", "surface2": "#665c54",
            "overlay0": "#7c6f64", "overlay1": "#928374", "overlay2": "#a89984",
            "subtext0": "#bdae93", "subtext1": "#d5c4a1", "text": "#ebdbb2",
            "rosewater": "#f2e5bc", "flamingo": "#f9d39b", "pink": "#d3869b",
            "mauve": "#b16286", "red": "#fb4934", "maroon": "#cc241d",
            "peach": "#fe8019", "yellow": "#fabd2f", "green": "#b8bb26",
            "teal": "#8ec07c", "sky": "#83a598", "sapphire": "#458588",
            "blue": "#83a598", "lavender": "#d3869b"
        },
        "nord": {
            "base": "#2e3440", "mantle": "#2b303b", "crust": "#272c36",
            "surface0": "#3b4252", "surface1": "#434c5e", "surface2": "#4c566a",
            "overlay0": "#616e88", "overlay1": "#6c7a96", "overlay2": "#7b88a1",
            "subtext0": "#d8dee9", "subtext1": "#e5e9f0", "text": "#eceff4",
            "rosewater": "#f0d8c9", "flamingo": "#ecc7b6", "pink": "#d5a8c8",
            "mauve": "#b48ead", "red": "#bf616a", "maroon": "#b0555d",
            "peach": "#d08770", "yellow": "#ebcb8b", "green": "#a3be8c",
            "teal": "#8fbcbb", "sky": "#88c0d0", "sapphire": "#81a1c1",
            "blue": "#5e81ac", "lavender": "#b48ead"
        },
        "tokyonight": {
            "base": "#24283b", "mantle": "#1f2335", "crust": "#1a1b26",
            "surface0": "#292e42", "surface1": "#343a52", "surface2": "#414868",
            "overlay0": "#565f89", "overlay1": "#6b7394", "overlay2": "#808aa3",
            "subtext0": "#a9b1d6", "subtext1": "#b4bbe0", "text": "#c0caf5",
            "rosewater": "#f7d7c4", "flamingo": "#f0c6c6", "pink": "#ff9ac4",
            "mauve": "#bb9af7", "red": "#f7768e", "maroon": "#ff9e64",
            "peach": "#ff9e64", "yellow": "#e0af68", "green": "#9ece6a",
            "teal": "#1abc9c", "sky": "#7dcfff", "sapphire": "#2ac3de",
            "blue": "#7aa2f7", "lavender": "#b4bbe0"
        },
        "rosepine": {
            "base": "#191724", "mantle": "#1f1d2e", "crust": "#16141f",
            "surface0": "#26233a", "surface1": "#403d52", "surface2": "#524f67",
            "overlay0": "#6e6a86", "overlay1": "#908caa", "overlay2": "#a6a2c4",
            "subtext0": "#c8c4de", "subtext1": "#d4d1e8", "text": "#e0def4",
            "rosewater": "#ebbcba", "flamingo": "#f2c5c1", "pink": "#eb6f92",
            "mauve": "#c4a7e7", "red": "#eb6f92", "maroon": "#d7827e",
            "peach": "#f6c177", "yellow": "#f6c177", "green": "#9ccfd8",
            "teal": "#9ccfd8", "sky": "#9ccfd8", "sapphire": "#31748f",
            "blue": "#31748f", "lavender": "#c4a7e7"
        },
        "dracula": {
            "base": "#282a36", "mantle": "#21222c", "crust": "#191a21",
            "surface0": "#343746", "surface1": "#44475a", "surface2": "#565972",
            "overlay0": "#6272a4", "overlay1": "#7b88bd", "overlay2": "#969ec9",
            "subtext0": "#c7c9de", "subtext1": "#e2e2ec", "text": "#f8f8f2",
            "rosewater": "#f5e0dc", "flamingo": "#ffb8b8", "pink": "#ff79c6",
            "mauve": "#bd93f9", "red": "#ff5555", "maroon": "#ff6e6e",
            "peach": "#ffb86c", "yellow": "#f1fa8c", "green": "#50fa7b",
            "teal": "#8be9fd", "sky": "#8be9fd", "sapphire": "#62d6e8",
            "blue": "#8be9fd", "lavender": "#bd93f9"
        },
        "everforest": {
            "base": "#2d353b", "mantle": "#272e33", "crust": "#232a2e",
            "surface0": "#343f44", "surface1": "#3d484d", "surface2": "#475258",
            "overlay0": "#4f585e", "overlay1": "#7a8478", "overlay2": "#859289",
            "subtext0": "#9da9a0", "subtext1": "#a7c080", "text": "#d3c6aa",
            "rosewater": "#e5c890", "flamingo": "#e69875", "pink": "#d699b6",
            "mauve": "#d699b6", "red": "#e67e80", "maroon": "#e69875",
            "peach": "#e69875", "yellow": "#dbbc7f", "green": "#a7c080",
            "teal": "#83c092", "sky": "#7fbbb3", "sapphire": "#7fbbb3",
            "blue": "#7fbbb3", "lavender": "#d699b6"
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
            'for n in $1; do [ -e "$0/$n.json" ] || echo "$n"; done',
            root.schemesDir, Object.keys(root.builtins).join(" ")]
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
