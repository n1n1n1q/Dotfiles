pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Reactive view of niri's `binds { }` block once it's been split out of
// config.kdl into ~/.config/niri/quickshell/binds.kdl (scripts/niri-split.sh).
// Parses every bind line into { chord, action, ... }, and writes changes back
// one line at a time via scripts/niri-keybind.py — with a validate + rollback
// around each edit, since a hand-typed chord is easy to get wrong. Nothing here
// touches config.kdl beyond the one-time split.
//
// A bind disabled from the page keeps its line, marked `//!` so niri ignores it
// but it still shows here (greyed, with an Enable button).
Singleton {
    id: root

    readonly property string niriDir: Quickshell.env("HOME") + "/.config/niri"
    readonly property string fragDir: niriDir + "/quickshell"
    readonly property string scriptDir: Quickshell.env("HOME") + "/.config/quickshell/scripts"
    readonly property string fragment: fragDir + "/binds.kdl"

    property bool split: false
    property bool busy: false
    // Set for a moment after niri rejects an edit and the fragment is rolled
    // back, so the page can say so.
    property string lastError: ""

    // --- parsed binds ---------------------------------------------------
    // [{ chord, props, action, category, label, disabled }]
    property var binds: []

    readonly property var _lineRe: /^(\s*)(\/\/!\s*)?([A-Za-z0-9_+]+)((?:\s+[^\s{]+)*)\s*\{\s*(.*?)\s*;?\s*\}\s*$/

    function _category(chord, action) {
        if (/\bqs\b|quickshell/.test(action)) return "shell";
        if (/^XF86Audio/.test(chord) || /playerctl|wpctl|pactl/.test(action)) return "media";
        if (/^XF86MonBrightness/.test(chord) || /brightnessctl/.test(action)) return "brightness";
        if (/^spawn(-sh)?\b/.test(action)) return "launch";
        // niri verbs — split by what they act on. Order matters: a verb like
        // move-column-to-workspace-down is a workspace bind, not a move bind.
        const v = action.split(/\s+/)[0];
        if (/workspace|overview/.test(v)) return "niri-workspace";
        if (/monitor/.test(v)) return "niri-monitor";
        if (/^move-|^swap-/.test(v)) return "niri-move";
        if (/^focus-/.test(v)) return "niri-focus";
        if (/column|width|height|consume|expel|preset|fullscreen|maximize|float|tabbed|center/.test(v))
            return "niri-layout";
        return "niri-misc";
    }

    // A short human label for the bind. niri's own `hotkey-overlay-title="…"`
    // property is the canonical description (it's what the built-in hotkey
    // overlay shows) — prefer it, then a known widget action, then a heuristic.
    function _label(action, props) {
        const title = (props || "").match(/hotkey-overlay-title="([^"]+)"/);
        if (title) return title[1];
        const s = root._sig(action);
        if (s) {
            const known = root.shellActions.find(a => a.sig === s);
            if (known) return known.label;
        }
        let m = action.match(/^spawn(?:-sh)?\s+"([^"]+)"/);
        if (m) {
            const prog = m[1].split(/\s+/)[0].split("/").pop();
            return prog.charAt(0).toUpperCase() + prog.slice(1);
        }
        const verb = action.split(/\s+/)[0];
        const rest = verb.replace(/-/g, " ");
        return rest.charAt(0).toUpperCase() + rest.slice(1);
    }

    // The `qs ipc call <target> <method> [arg]` signature of an action, or "".
    function _sig(action) {
        const toks = (action.match(/"[^"]*"|\S+/g) || []).map(t => t.replace(/^"|"$/g, ""));
        const i = toks.indexOf("call");
        if (i === -1) return "";
        return toks.slice(i + 1).join(" ").toLowerCase().trim();
    }

    function _parse(text) {
        const out = [];
        for (const raw of text.split("\n")) {
            const line = raw.replace(/\s+$/, "");
            const t = line.trim();
            if (!t || t === "binds {" || t === "}") continue;
            const m = root._lineRe.exec(line);
            if (!m) continue;
            const chord = m[3];
            const action = m[5];
            const props = (m[4] || "").trim();
            out.push({
                chord: chord,
                props: props,
                action: action,
                category: root._category(chord, action),
                label: root._label(action, props),
                sig: root._sig(action),
                disabled: !!m[2]
            });
        }
        const rank = { shell: 0, launch: 1, media: 2, brightness: 3, niri: 4 };
        return out.map((b, i) => ({ b, i }))
            .sort((x, y) => (rank[x.b.category] - rank[y.b.category]) || (x.i - y.i))
            .map(o => o.b);
    }

    function bindsIn(category) {
        return binds.filter(b => b.category === category);
    }

    readonly property var categoryMeta: [
        { key: "launch",         title: "Applications",   icon: "󰀻", hint: "Binds that spawn a program" },
        { key: "media",          title: "Media & volume", icon: "󰝚", hint: "Playback and audio keys" },
        { key: "brightness",     title: "Brightness",     icon: "󰃟", hint: "" },
        { key: "niri-focus",     title: "Focus",          icon: "󰆾", hint: "Move focus between windows, columns and monitors" },
        { key: "niri-move",      title: "Move & swap",    icon: "󰆾", hint: "Reposition the focused window or column" },
        { key: "niri-layout",    title: "Layout & sizing", icon: "󰉡", hint: "Column widths, fullscreen, floating, tabbed" },
        { key: "niri-workspace", title: "Workspaces",     icon: "󰧨", hint: "Switch and reorder workspaces, overview" },
        { key: "niri-monitor",   title: "Monitors",       icon: "󰍹", hint: "Move focus and windows between outputs" },
        { key: "niri-misc",      title: "Other niri",     icon: "󱂬", hint: "Close, screenshot, quit, power" }
    ]

    // --- quickshell widget / shell actions ---------------------------
    // These always show as a row, whether bound or not — they can't be removed,
    // only bound to a key or set to none.
    readonly property var shellActions: [
        { sig: "dashboard toggle",        label: "Toggle dashboard",       desc: "The drop-down panel on the left of the bar" },
        { sig: "settings toggle",         label: "Open settings",          desc: "This window" },
        { sig: "launcher toggle",         label: "Open the app launcher",  desc: "" },
        { sig: "notifications dnd",       label: "Toggle do not disturb",  desc: "Silence popups; the centre still records them" },
        { sig: "notifications clear",     label: "Clear notifications",    desc: "" },
        { sig: "bar edit",               label: "Edit the bar layout",    desc: "" },
        { sig: "popout toggle calendar",  label: "Toggle calendar popout", desc: "" },
        { sig: "picker wallpaper",        label: "Wallpaper picker",       desc: "Browse wallpapers left-to-right" },
        { sig: "picker theme",            label: "Theme picker",           desc: "Browse colour schemes left-to-right" },
        { sig: "wallpaper next",          label: "Next wallpaper",         desc: "" },
        { sig: "wallpaper prev",          label: "Previous wallpaper",     desc: "" },
        { sig: "scheme next",             label: "Next colour scheme",     desc: "" },
        { sig: "scheme prev",             label: "Previous colour scheme", desc: "" },
        { sig: "lock lock",               label: "Lock the screen",        desc: "" },
        { sig: "caffeine toggle",         label: "Keep awake",             desc: "Hold off sleep, screen-blank and idle-lock" },
        { sig: "display menu",            label: "Display mode menu",      desc: "Win+P-style extend / single-display switcher" }
    ]

    function _bodyForSig(sig) {
        const parts = ["spawn", '"qs"', '"ipc"', '"call"']
            .concat(sig.split(" ").map(p => `"${p}"`));
        return parts.join(" ");
    }
    function _titleForSig(sig) {
        return (shellActions.find(a => a.sig === sig) || {}).label || "";
    }

    // One row per shellActions entry, merged with the bind (if any) driving it.
    readonly property var shellActionRows: {
        const bySig = {};
        for (const b of binds) if (b.sig) bySig[b.sig] = b;
        return shellActions.map(a => {
            const b = bySig[a.sig];
            return {
                sig: a.sig, label: a.label, desc: a.desc,
                chord: b ? b.chord : "", bound: !!b,
                disabled: b ? b.disabled : false
            };
        });
    }
    // Shell binds the user added that aren't one of the known widget actions.
    readonly property var extraShellBinds: {
        const known = shellActions.map(a => a.sig);
        return binds.filter(b => b.category === "shell" && known.indexOf(b.sig) === -1);
    }

    // --- shell keybinds seeded on first split ------------------------
    readonly property var shellDefaults: [
        { chord: "Mod+Space",   sig: "dashboard toggle" },
        { chord: "Mod+Comma",   sig: "settings toggle" },
        { chord: "Mod+Slash",   sig: "launcher toggle" },
        { chord: "Mod+Shift+N", sig: "notifications dnd" },
        { chord: "Mod+Shift+W", sig: "picker wallpaper" },
        { chord: "Mod+Shift+T", sig: "picker theme" },
        { chord: "Mod+Alt+L",   sig: "lock lock" },
        { chord: "Mod+P",       sig: "display menu" }
    ]
    readonly property bool hasShellBinds: binds.some(b => b.category === "shell")

    // --- files --------------------------------------------------------
    FileView {
        id: file
        path: root.split ? root.fragment : ""
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.binds = root._parse(text())
    }

    // --- split detection --------------------------------------------
    Process {
        id: detectProc
        readonly property string cfg: root.niriDir + "/config.kdl"
        command: ["sh", "-c",
            `grep -Eq '^[[:space:]]*include[[:space:]]+"quickshell/binds.kdl"' "${detectProc.cfg}" ` +
            `&& [ -f "${root.fragment}" ] && echo yes || echo no`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.split = text.trim() === "yes";
                if (root.split) file.reload();
            }
        }
    }

    // --- edit / split actions -------------------------------------
    Process {
        id: splitProc
        command: ["bash", root.scriptDir + "/niri-split.sh"]
        onExited: {
            root.busy = false;
            detectProc.running = true;
            seedProc.running = true;
        }
    }

    Process {
        id: seedProc
        command: ["sh", "-c",
            root.shellDefaults.map(d =>
                `python3 "${root.scriptDir}/niri-keybind.py" "${root.fragment}" add ` +
                `'${d.chord}' '${root._bodyForSig(d.sig)}' '${root._titleForSig(d.sig)}' || true`
            ).join("; ") + `; niri msg action load-config-file >/dev/null 2>&1 || true`]
        onExited: file.reload()
    }

    // Every mutating op, wrapped: backup -> edit -> validate -> rollback.
    Process {
        id: editProc
        property string op: ""
        property string a: ""
        property string b: ""
        property string c: ""
        command: ["sh", "-c",
            `f="${root.fragment}"; cp "$f" "$f.bak"; ` +
            `python3 "${root.scriptDir}/niri-keybind.py" "$f" ${editProc.op} '${editProc.a}' '${editProc.b}' '${editProc.c}'; rc=$?; ` +
            `if [ $rc -eq 1 ]; then echo ERR; cp "$f.bak" "$f"; rm -f "$f.bak"; exit 0; fi; ` +
            `if niri validate >/dev/null 2>&1; then rm -f "$f.bak"; else echo ERR; cp "$f.bak" "$f"; rm -f "$f.bak"; fi; ` +
            `niri msg action load-config-file >/dev/null 2>&1 || true`]
        stdout: StdioCollector {
            onStreamFinished: root.lastError = text.indexOf("ERR") !== -1
                ? "niri rejected that change — reverted" : ""
        }
        onExited: {
            root.busy = false;
            file.reload();
        }
    }

    function runSplit() {
        if (busy) return;
        busy = true;
        splitProc.running = true;
    }
    function seedShellDefaults() {
        if (busy || seedProc.running) return;
        seedProc.running = true;
    }

    function _edit(op, a, b, c) {
        if (editProc.running) return;
        busy = true;
        lastError = "";
        editProc.op = op;
        editProc.a = a;
        editProc.b = b || "";
        editProc.c = c || "";
        editProc.running = true;
    }

    // Change a bind's key combo. `newChord` is a niri chord, e.g. "Mod+Shift+Return".
    function rechord(oldChord, newChord) {
        if (!newChord || newChord === oldChord) return;
        _edit("rechord", oldChord, newChord);
    }
    // Replace what a bind does — `body` is the text inside the braces.
    function setAction(chord, body) {
        if (!body) return;
        _edit("action", chord, body);
    }
    // Delete a bind's line entirely.
    function remove(chord) {
        if (!chord) return;
        _edit("remove", chord);
    }
    // Keep the line but comment it out (`//!`), or bring it back.
    function disable(chord) {
        if (!chord) return;
        _edit("disable", chord);
    }
    function enable(chord) {
        if (!chord) return;
        _edit("enable", chord);
    }

    // --- widget-action helpers -------------------------------------
    // Bind (or rebind) a quickshell widget action to `chord`.
    function bindShellAction(sig, chord) {
        if (!chord) return;
        const existing = binds.find(b => b.sig === sig);
        if (existing) {
            if (existing.chord !== chord) _edit("rechord", existing.chord, chord);
        } else {
            _edit("add", chord, root._bodyForSig(sig), root._titleForSig(sig));
        }
    }
    // Unbind a widget action — the row stays, the key is freed.
    function clearShellAction(sig) {
        const existing = binds.find(b => b.sig === sig);
        if (existing) _edit("remove", existing.chord);
    }

    Component.onCompleted: detectProc.running = true
}
