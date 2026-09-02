pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Reactive view of the niri `layout` / `animations` / `output "..."` blocks
// once they've been split out of config.kdl into ~/.config/niri/quickshell/*.kdl
// (see scripts/niri-split.sh). Reads current values straight from those
// fragment files and writes them back surgically via scripts/niri-set.py,
// then asks niri to reload. Nothing here touches the user's main config.kdl
// beyond the one-time split.
Singleton {
    id: root

    readonly property string niriDir: Quickshell.env("HOME") + "/.config/niri"
    readonly property string fragDir: niriDir + "/quickshell"
    readonly property string scriptDir: Quickshell.env("HOME") + "/.config/quickshell/scripts"

    // Split state — `split` gates the layout/animations options, `outputsSplit`
    // the display options. `runSplit()` does all three; a config split before
    // outputs support existed just needs one more run.
    property bool split: false
    property bool outputsSplit: false
    property bool inputSplit: false
    property bool busy: false

    // --- live values, parsed from the fragments -------------------------
    property int gaps: 8
    property bool focusRing: true
    property int focusRingWidth: 4
    property bool border: false
    property int borderWidth: 4
    property bool animations: true
    property real animationSlowdown: 1.0

    function _num(text, re, fallback) {
        const m = text.match(re);
        return m ? parseFloat(m[1]) : fallback;
    }

    function _parseLayout(text) {
        gaps = _num(text, /^\s*gaps\s+(\d+)/m, gaps);
        const ring = text.match(/focus-ring\s*\{([\s\S]*?)\n\s*\}/)?.[1] ?? "";
        const bord = text.match(/\bborder\s*\{([\s\S]*?)\n\s*\}/)?.[1] ?? "";
        focusRing = !/^\s*off\s*$/m.test(ring);
        focusRingWidth = _num(ring, /^\s*width\s+(\d+)/m, focusRingWidth);
        border = !/^\s*off\s*$/m.test(bord);
        borderWidth = _num(bord, /^\s*width\s+(\d+)/m, borderWidth);
    }
    function _parseAnims(text) {
        animations = !/^\s*off\s*$/m.test(text);
        animationSlowdown = _num(text, /^\s*slowdown\s+([\d.]+)/m, 1.0);
    }

    // --- input (touchpad / mouse / keyboard behaviour) ------------------
    property bool tpTap: false
    property bool tpNaturalScroll: false
    property bool tpDwt: false
    property real tpAccel: 0
    property bool mouseNaturalScroll: false
    property real mouseAccel: 0
    property int kbRepeatDelay: 600
    property int kbRepeatRate: 25
    property bool focusFollowsMouse: false
    property bool warpMouseToFocus: false

    function _block(text, name) {
        return text.match(new RegExp("\\b" + name + "\\s*\\{([\\s\\S]*?)\\n\\s*\\}"))?.[1] ?? "";
    }
    function _parseInput(text) {
        // Strip the nested sub-blocks so top-level flags aren't matched inside them.
        const top = text.replace(/\b(keyboard|touchpad|mouse|trackpoint|tablet|touch)\s*\{[\s\S]*?\n\s*\}/g, "");
        const tp = _block(text, "touchpad");
        const ms = _block(text, "mouse");
        tpTap = /^\s*tap\s*$/m.test(tp);
        tpNaturalScroll = /^\s*natural-scroll\s*$/m.test(tp);
        tpDwt = /^\s*dwt\s*$/m.test(tp);
        tpAccel = _num(tp, /^\s*accel-speed\s+(-?[\d.]+)/m, 0);
        mouseNaturalScroll = /^\s*natural-scroll\s*$/m.test(ms);
        mouseAccel = _num(ms, /^\s*accel-speed\s+(-?[\d.]+)/m, 0);
        // repeat-delay / repeat-rate only ever live in the keyboard block.
        kbRepeatDelay = _num(text, /^\s*repeat-delay\s+(\d+)/m, 600);
        kbRepeatRate = _num(text, /^\s*repeat-rate\s+(\d+)/m, 25);
        focusFollowsMouse = /^\s*focus-follows-mouse\b/m.test(top);
        warpMouseToFocus = /^\s*warp-mouse-to-focus\s*$/m.test(top);
    }

    // --- outputs ------------------------------------------------------
    // Per-connector configured state, merged with live info (modes, make) from
    // `niri msg -j outputs`. Each entry:
    //   { name, off, mode, scale, transform, vrr, position,
    //     make, model, modes:[{label,w,h,r,preferred}], currentMode }
    property var outputs: []
    property var _liveOutputs: ({})

    function _parseOutputs(text) {
        const cfg = {};
        const re = /output\s+"([^"]+)"\s*\{([\s\S]*?)\n\}/g;
        let m;
        while ((m = re.exec(text)) !== null) {
            const name = m[1];
            const u = m[2].replace(/^[^\S\n]*\/\/.*$/gm, "");   // drop comment lines
            const pos = u.match(/^\s*position\s+x=(-?\d+)\s+y=(-?\d+)/m);
            cfg[name] = {
                off: /^\s*off\s*$/m.test(u),
                mode: u.match(/^\s*mode\s+"([^"]+)"/m)?.[1] ?? "",
                scale: parseFloat(u.match(/^\s*scale\s+([\d.]+)/m)?.[1] ?? "1"),
                transform: u.match(/^\s*transform\s+"([^"]+)"/m)?.[1] ?? "normal",
                vrr: /variable-refresh-rate\s+on-demand=true/.test(u) ? "ondemand"
                    : /^\s*variable-refresh-rate\s*$/m.test(u) ? "on" : "off",
                position: pos ? (pos[1] + "," + pos[2]) : ""
            };
        }
        _mergeOutputs(cfg);
    }

    function _mergeOutputs(cfg) {
        const names = new Set([...Object.keys(cfg), ...Object.keys(_liveOutputs)]);
        const list = [];
        for (const name of names) {
            const c = cfg[name] ?? { off: false, mode: "", scale: 1, transform: "normal", vrr: "off", position: "" };
            const live = _liveOutputs[name] ?? {};
            const modes = (live.modes ?? []).map(md => ({
                label: `${md.width}×${md.height} @ ${(md.refresh_rate / 1000).toFixed(3)}`,
                value: `${md.width}x${md.height}@${(md.refresh_rate / 1000).toFixed(3)}`,
                preferred: !!md.is_preferred
            }));
            list.push(Object.assign({}, c, {
                name,
                make: live.make ?? "",
                model: live.model ?? "",
                modes,
                connected: !!live.modes
            }));
        }
        list.sort((a, b) => a.name.localeCompare(b.name));
        outputs = list;
    }

    Process {
        id: liveOutputsProc
        command: ["niri", "msg", "-j", "outputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root._liveOutputs = JSON.parse(text);
                    if (outputsFile.path) outputsFile.reload();
                    else root._mergeOutputs({});
                } catch (e) {}
            }
        }
    }
    function refreshOutputs() { liveOutputsProc.running = true; }

    // --- fragment files ------------------------------------------------
    // Empty path until the split has happened, so a missing fragment doesn't
    // spam the log before setup.
    FileView {
        id: layoutFile
        path: root.split ? (root.fragDir + "/layout.kdl") : ""
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root._parseLayout(text())
    }
    FileView {
        id: animFile
        path: root.split ? (root.fragDir + "/animations.kdl") : ""
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root._parseAnims(text())
    }
    FileView {
        id: outputsFile
        path: root.outputsSplit ? (root.fragDir + "/outputs.kdl") : ""
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root._parseOutputs(text())
    }
    FileView {
        id: inputFile
        path: root.inputSplit ? (root.fragDir + "/input.kdl") : ""
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root._parseInput(text())
    }

    // --- split detection --------------------------------------------
    Process {
        id: detectProc
        readonly property string cfg: root.niriDir + "/config.kdl"
        command: ["sh", "-c",
            `c="${detectProc.cfg}"; ` +
            `l=no; o=no; i=no; ` +
            `grep -Eq '^[[:space:]]*include[[:space:]]+"quickshell/layout.kdl"' "$c" && [ -f "${root.fragDir}/layout.kdl" ] && l=yes; ` +
            `grep -Eq '^[[:space:]]*include[[:space:]]+"quickshell/outputs.kdl"' "$c" && [ -f "${root.fragDir}/outputs.kdl" ] && o=yes; ` +
            `grep -Eq '^[[:space:]]*include[[:space:]]+"quickshell/input.kdl"' "$c" && [ -f "${root.fragDir}/input.kdl" ] && i=yes; ` +
            `echo "$l $o $i"`]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ");
                root.split = parts[0] === "yes";
                root.outputsSplit = parts[1] === "yes";
                root.inputSplit = parts[2] === "yes";
                if (root.split) { layoutFile.reload(); animFile.reload(); }
                if (root.outputsSplit) outputsFile.reload();
                if (root.inputSplit) inputFile.reload();
                root.refreshOutputs();
            }
        }
    }

    // --- actions ---------------------------------------------------
    Process {
        id: splitProc
        command: ["bash", root.scriptDir + "/niri-split.sh"]
        onExited: {
            root.busy = false;
            detectProc.running = true;
        }
    }
    Process {
        id: setProc
        property string frag: ""
        property string key: ""
        property string value: ""
        command: ["sh", "-c",
            `python3 "${root.scriptDir}/niri-set.py" "${root.fragDir}/${setProc.frag}" "${setProc.key}" "${setProc.value}"; ` +
            `niri msg action load-config-file >/dev/null 2>&1 || true`]
        onExited: root.busy = false
    }

    Process {
        id: reloadProc
        command: ["niri", "msg", "action", "load-config-file"]
    }

    function runSplit() {
        if (root.busy) return;
        root.busy = true;
        splitProc.running = true;
    }
    function reloadNiri() {
        reloadProc.running = true;
    }
    function set(frag, key, value) {
        if (setProc.running) return;
        root.busy = true;
        setProc.frag = frag;
        setProc.key = key;
        setProc.value = String(value);
        setProc.running = true;
    }
    function setOutput(name, attr, value) {
        set("outputs.kdl", "output." + name + "." + attr, value);
    }
    // `key` is the part after "input." — e.g. "touchpad.tap", "mouse.accel-speed",
    // "keyboard.repeat-delay", "focus-follows-mouse".
    function setInput(key, value) {
        set("input.kdl", "input." + key, value);
    }

    Component.onCompleted: detectProc.running = true
}
