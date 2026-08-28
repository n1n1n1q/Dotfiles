pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Wallpaper handling via awww (the awww-daemon is started by niri at login).
// `Appearance.wallpaper` holds the selected absolute path — this service watches
// it and pushes it to awww, keeps a scanned list of the wallpapers folder, and
// copies newly-added images into it.
//
//   ~/.config/quickshell/wallpapers/   <- drop images here (or use "Add…")
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/quickshell/wallpapers"

    // Absolute paths of every image in the folder, name-sorted.
    property var wallpapers: []
    readonly property string current: Appearance.wallpaper

    function reload() { scanProc.running = true; }

    function select(path) { Appearance.setWallpaper(path); }

    // Copy an image chosen from anywhere into the wallpapers folder, then
    // select it.
    function addFromFile(src) {
        if (!src || src.length === 0) return;
        copyProc.exec({
            "environment": { "SRC": src, "DIR": root.dir },
            "command": ["bash", "-c",
                'mkdir -p "$DIR" && cp -f -- "$SRC" "$DIR/" && basename -- "$SRC"']
        });
    }

    function remove(path) {
        if (!path || path.length === 0) return;
        if (path === root.current) Appearance.setWallpaper("");
        rmProc.exec(["rm", "-f", "--", path]);
    }

    function _apply(path) {
        if (!path || path.length === 0) return;
        applyProc.exec({
            "environment": { "WP": path },
            "command": ["bash", "-c",
                'flags="--transition-type fade --transition-duration 1 --transition-fps 60"; ' +
                'awww img "$WP" $flags 2>/dev/null || ' +
                '{ awww-daemon >/dev/null 2>&1 & sleep 1; awww img "$WP" $flags; }']
        });
    }

    onCurrentChanged: _apply(current)

    Component.onCompleted: {
        reload();
        _apply(current);
    }

    Process {
        id: scanProc
        command: ["bash", "-c",
            'shopt -s nullglob nocaseglob; ' +
            'for f in "$0"/*.{jpg,jpeg,png,webp,gif,bmp}; do [ -f "$f" ] && printf "%s\\n" "$f"; done | sort -u',
            root.dir]
        stdout: StdioCollector {
            onStreamFinished: root.wallpapers = text.trim().split("\n").filter(l => l.length > 0)
        }
    }

    Process { id: applyProc }

    Process {
        id: copyProc
        stdout: StdioCollector {
            onStreamFinished: {
                const name = text.trim();
                root.reload();
                if (name.length > 0)
                    Appearance.setWallpaper(root.dir + "/" + name);
            }
        }
    }

    Process {
        id: rmProc
        onExited: root.reload()
    }
}
