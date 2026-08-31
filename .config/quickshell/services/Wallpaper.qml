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
//
// Beyond the grid in Settings > Appearance, the folder can be walked from a
// keybind without opening anything (see the IpcHandler at the bottom):
//
//   qs ipc call wallpaper next
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/quickshell/wallpapers"

    // Absolute paths of every image in the folder, name-sorted.
    property var wallpapers: []
    readonly property string current: Appearance.wallpaper

    // Position of the active wallpaper in `wallpapers`; -1 when nothing is set
    // or the saved path has since been deleted from the folder.
    readonly property int currentIndex: wallpapers.indexOf(current)

    // Emitted when a wallpaper is *stepped* to (keybind / IPC) rather than
    // picked in Settings — the OSD listens for this and flashes a preview pill.
    // The path is "" when the folder turned out to be empty.
    signal cycled(string path)

    // A step asked for before the folder had been scanned; replayed once the
    // scan lands. "" | "next" | "prev" | "random"
    property string _pending: ""

    function reload() { scanProc.running = true; }

    function select(path) { Appearance.setWallpaper(path); }

    // --- cycling ------------------------------------------------------------
    // Walk the folder in name order, wrapping at both ends.
    function cycle(step) {
        if (wallpapers.length === 0) {
            // Nothing scanned yet, or images were dropped in after startup —
            // rescan and replay the step once the list lands.
            _pending = step >= 0 ? "next" : "prev";
            reload();
            return;
        }
        const n = wallpapers.length;
        // Nothing selected yet: a forward step lands on the first entry, a
        // backward one on the last.
        const i = currentIndex < 0
            ? (step >= 0 ? 0 : n - 1)
            : ((currentIndex + step) % n + n) % n;
        _step(wallpapers[i]);
    }

    function next() { cycle(1); }
    function previous() { cycle(-1); }

    function random() {
        if (wallpapers.length === 0) {
            _pending = "random";
            reload();
            return;
        }
        // Never hand back the one already on screen — a shuffle that changes
        // nothing reads as a dead keybind.
        const pool = wallpapers.filter(w => w !== current);
        const from = pool.length > 0 ? pool : wallpapers;
        _step(from[Math.floor(Math.random() * from.length)]);
    }

    // Apply *and* announce. `select` alone stays silent, and stepping onto the
    // wallpaper that is already set doesn't move `current` at all — the OSD
    // should still confirm the keypress either way.
    function _step(path) {
        select(path);
        cycled(path);
    }

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
            onStreamFinished: {
                root.wallpapers = text.trim().split("\n").filter(l => l.length > 0);
                if (root._pending === "") return;
                const p = root._pending;
                root._pending = "";     // always cleared, so a genuinely empty
                                        // folder can't loop rescan -> replay
                if (root.wallpapers.length === 0)
                    root.cycled("");    // let the OSD say the folder is empty
                else if (p === "random")
                    root.random();
                else
                    root.cycle(p === "prev" ? -1 : 1);
            }
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

    // Drives the folder from a niri keybind or a script:
    //   qs ipc call wallpaper next
    IpcHandler {
        target: "wallpaper"

        function next(): void { root.cycle(1); }
        function prev(): void { root.cycle(-1); }
        function random(): void { root.random(); }
        function set(path: string): void { root._step(path); }
        function reload(): void { root.reload(); }
        function current(): string { return root.current; }
        function list(): string { return root.wallpapers.join("\n"); }
    }
}
