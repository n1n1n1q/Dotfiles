pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history, backed by `cliphist` (+ `wl-clipboard`). The shell runs
// the `wl-paste --watch cliphist store` capture itself, so nothing needs adding
// to the niri config — install `cliphist` and `wl-clipboard` and it works.
//
// `available` is false until both tools are on PATH; the launcher's clipboard
// mode shows a one-line "install cliphist" hint in that case.
Singleton {
    id: root

    property bool available: false
    // [{ id, raw, preview, isImage }] — newest first, as `cliphist list` gives.
    property var entries: []
    readonly property int count: entries.length

    signal changed()

    // --- availability -------------------------------------------------
    Process {
        id: checkProc
        running: true
        command: ["sh", "-c",
            "command -v cliphist >/dev/null 2>&1 && command -v wl-copy >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1 && echo ok"]
        stdout: StdioCollector {
            onStreamFinished: root.available = text.trim() === "ok"
        }
        onExited: {
            if (!root.available)
                return;
            watchText.running = true;
            watchImage.running = true;
            monitor.running = true;
            root.refresh();
        }
    }

    // --- capture ----------------------------------------------------
    // Two long-lived watchers (cliphist wants text and image fed separately).
    Process {
        id: watchText
        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "store"]
    }
    Process {
        id: watchImage
        command: ["wl-paste", "--type", "image", "--watch", "cliphist", "store"]
    }

    // A third watcher just to learn *that* the clipboard changed, so the list
    // stays current while the launcher is open.
    Process {
        id: monitor
        command: ["wl-paste", "--watch", "sh", "-c", "printf 'x\\n'"]
        stdout: SplitParser {
            onRead: refreshDebounce.restart()
        }
    }
    Timer {
        id: refreshDebounce
        interval: 250
        onTriggered: root.refresh()
    }

    // --- list -----------------------------------------------------
    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    function refresh() {
        if (root.available)
            listProc.running = true;
    }

    function _parse(text) {
        const out = [];
        const lines = text.split("\n");
        for (const line of lines) {
            if (line.length === 0)
                continue;
            const tab = line.indexOf("\t");
            if (tab < 0)
                continue;
            const id = line.slice(0, tab);
            const preview = line.slice(tab + 1);
            const isImage = /^\[\[\s*binary data.*(png|jpe?g|gif|bmp|webp|tiff)/i.test(preview);
            out.push({
                "id": id,
                "raw": line,
                "preview": preview.replace(/\s+/g, " ").trim(),
                "isImage": isImage
            });
        }
        root.entries = out;
        root.changed();
    }

    // --- actions --------------------------------------------------
    // cliphist decode reads the selected line from stdin and keys off its
    // leading id; the id is all it needs, and it's numeric, so nothing
    // sensitive or shell-special goes through the command line.
    Process { id: decodeProc }
    Process { id: deleteProc; onExited: root.refresh() }
    Process { id: wipeProc; onExited: root.refresh() }

    function copy(entry) {
        if (!root.available || !entry)
            return;
        decodeProc.exec({
            "environment": { "CID": String(entry.id) },
            "command": ["sh", "-c", "printf '%s\\t' \"$CID\" | cliphist decode | wl-copy"]
        });
    }

    function remove(entry) {
        if (!root.available || !entry)
            return;
        deleteProc.exec({
            "environment": { "CID": String(entry.id) },
            "command": ["sh", "-c", "printf '%s\\t' \"$CID\" | cliphist delete"]
        });
    }

    function wipe() {
        if (!root.available)
            return;
        wipeProc.exec({ "command": ["cliphist", "wipe"] });
    }
}
