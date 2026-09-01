pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The installed applications, ranked against a search query — everything the
// launcher knows about .desktop files.
//
// Two halves: a scoring pass over a lowercased copy of each entry's searchable
// fields (name, id, generic name, keywords, Exec, comment), and a small usage
// counter that nudges the apps you actually open to the top of an otherwise
// even match. The counter lives in its own file rather than launcher.json
// because it is machine-written churn, not configuration:
//
//   ~/.config/quickshell/launcher-usage.json   { "firefox": { "n": 12, "t": ... } }
Singleton {
    id: root

    // Everything that asks to be shown, deduped by id — a few packages ship
    // the same entry under two paths and the launcher shouldn't list it twice.
    readonly property var list: Array.from(DesktopEntries.applications.values)
        .filter(a => a && !a.noDisplay)
        .filter((a, i, self) => i === self.findIndex(b => b.id === a.id))

    // The search corpus. Lowercasing once here rather than per keystroke is
    // most of why typing stays smooth with a few hundred entries installed.
    readonly property var index: list.map(a => ({
        entry: a,
        id: a.id ?? "",
        lname: (a.name ?? "").toLowerCase(),
        lid: (a.id ?? "").toLowerCase(),
        lgeneric: (a.genericName ?? "").toLowerCase(),
        lkeywords: Array.from(a.keywords ?? []).join(" ").toLowerCase(),
        lexec: (a.execString ?? "").toLowerCase(),
        lcomment: (a.comment ?? "").toLowerCase(),
        actions: Array.from(a.actions ?? [])
    }))

    // Which haystack is worth how much. A hit on the name is the real thing;
    // one buried in the comment is a last resort, and scores like it.
    readonly property var fields: [
        { key: "lname",     weight: 1.00 },
        { key: "lid",       weight: 0.86 },
        { key: "lgeneric",  weight: 0.80 },
        { key: "lkeywords", weight: 0.75 },
        { key: "lexec",     weight: 0.70 },
        { key: "lcomment",  weight: 0.55 }
    ]

    // --- scoring ------------------------------------------------------------
    // One haystack against an already-lowercased needle, 0 for no match. The
    // four tiers, in order: the whole string, a prefix, a word start, a hit
    // mid-word — then, failing all of those, a scattered subsequence.
    function _score(hay, q) {
        if (hay.length === 0 || q.length === 0)
            return 0;
        const i = hay.indexOf(q);
        if (i === 0)
            return hay.length === q.length ? 1.0 : 0.92;
        if (i > 0)
            return _atBoundary(hay, i) ? 0.80 : 0.66;
        return _subsequence(hay, q);
    }

    function _atBoundary(hay, i) {
        const c = hay.charAt(i - 1);
        return c === " " || c === "-" || c === "_" || c === "." || c === "/";
    }

    // Every character of `q` present in order. Scores on how much of the match
    // stayed contiguous and how early it started, so "gimp" landing as one run
    // beats the same letters scattered across a sentence.
    function _subsequence(hay, q) {
        let at = 0, runs = 0, prev = -2, first = -1;
        for (let k = 0; k < q.length; k++) {
            const j = hay.indexOf(q.charAt(k), at);
            if (j < 0)
                return 0;
            if (first < 0) first = j;
            if (j !== prev + 1) runs++;
            prev = j;
            at = j + 1;
        }
        const contiguity = 1 - (runs - 1) / q.length;
        const earliness = 1 - Math.min(first, 20) / 20;
        // Caps out below the mid-word substring tier above, which is the point:
        // a real substring hit should always outrank a scattered one.
        return 0.20 + 0.25 * contiguity + 0.10 * earliness;
    }

    // --- usage --------------------------------------------------------------
    readonly property var usage: usageAdapter.entries ?? ({})

    function useCount(id) { return usage[id]?.n ?? 0; }

    // A small thumb on the scale, never enough to float an unrelated app over
    // a real match: eight opens is worth about as much as one tier of match
    // quality, and it stops climbing after that.
    function _frecency(id) {
        if (!LauncherConfig.frecency)
            return 0;
        const e = usage[id];
        if (!e)
            return 0;
        const bonus = Math.min(0.12, 0.03 * Math.log2(1 + (e.n ?? 0)));
        const fresh = (Date.now() - (e.t ?? 0)) < 86400000 ? 0.03 : 0;
        return bonus + fresh;
    }

    function bump(id) {
        if (!id || id.length === 0)
            return;
        const u = JSON.parse(JSON.stringify(usage));
        const e = u[id] ?? { n: 0, t: 0 };
        u[id] = { n: (e.n ?? 0) + 1, t: Date.now() };
        usageAdapter.entries = u;
    }

    function forget() { usageAdapter.entries = ({}); }

    // --- querying -----------------------------------------------------------
    // Returns [{ entry, action, score }] — `action` is null for the app itself
    // and a DesktopAction for one of its right-click entries ("New Window",
    // "Open Private Window", ...), which are matched as "<app> <action>" so
    // they only surface once the query says which one.
    function query(text, limit) {
        const q = String(text || "").trim().toLowerCase();
        const cap = limit ?? LauncherConfig.maxResults;

        if (q.length === 0)
            return _recent(cap);

        // Actions are matched as "<app> <action>", so they only make sense
        // once the query is more than one word — "firefox priv" is asking for
        // one, "cal" is not, and scoring them on a single word turns every
        // loose subsequence hit into three extra rows.
        const wantActions = /\s/.test(q);

        const out = [];
        for (const it of index) {
            let best = 0;
            for (const f of fields) {
                const s = root._score(it[f.key], q) * f.weight;
                if (s > best) best = s;
            }

            if (wantActions) {
                for (const a of it.actions) {
                    const name = (a.name ?? "").toLowerCase();
                    if (name.length === 0)
                        continue;
                    const s = root._score(it.lname + " " + name, q);
                    // Above the app's own score, or it is just a worse way of
                    // saying what the app row already said.
                    if (s > best)
                        out.push({ entry: it.entry, action: a, score: s });
                }
            }

            if (best > 0)
                out.push({ entry: it.entry, action: null,
                           score: best + root._frecency(it.id) });
        }

        out.sort((a, b) => b.score - a.score
            || String(a.entry.name).localeCompare(String(b.entry.name)));
        return out.slice(0, cap);
    }

    // An empty query still has something useful to say: the apps this shell
    // has actually been used to open, most-used first, padded out with the
    // rest in name order.
    function _recent(cap) {
        const used = [];
        const rest = [];
        for (const it of index)
            (useCount(it.id) > 0 && LauncherConfig.frecency ? used : rest)
                .push(it);

        used.sort((a, b) => (usage[b.id]?.n ?? 0) - (usage[a.id]?.n ?? 0)
            || (usage[b.id]?.t ?? 0) - (usage[a.id]?.t ?? 0));
        rest.sort((a, b) => a.lname.localeCompare(b.lname));

        return used.concat(rest)
            .slice(0, cap)
            .map(it => ({ entry: it.entry, action: null, score: 0 }));
    }

    // --- launching ----------------------------------------------------------
    function launch(entry, action) {
        if (!entry)
            return;
        bump(entry.id);

        const target = action ?? entry;
        // Terminal: false is the common case and DesktopEntry already knows how
        // to spawn it, field codes and working directory included.
        if (!entry.runInTerminal) {
            target.execute();
            return;
        }
        runInTerminal(target.command, entry.workingDirectory);
    }

    // `-e` is the one spelling every terminal worth configuring understands.
    // The configured value is split on whitespace so "gnome-terminal --" and
    // friends can carry their own arguments.
    function runInTerminal(argv, cwd) {
        const term = String(LauncherConfig.terminal || "").trim()
            .split(/\s+/).filter(s => s.length > 0);
        const cmd = Array.from(argv ?? []);
        if (term.length === 0 || cmd.length === 0)
            return;

        const ctx = { "command": term.concat(["-e"]).concat(cmd) };
        if (cwd && cwd.length > 0)
            ctx.workingDirectory = cwd;
        Quickshell.execDetached(ctx);
    }

    // Theme icon for an entry, falling back to the generic binary glyph so a
    // row is never left with a broken image where its icon should be.
    function iconSource(entry) {
        const name = entry?.icon ?? "";
        if (name.length === 0)
            return Quickshell.iconPath("application-x-executable", "");
        if (name.startsWith("/") || name.startsWith("file:"))
            return name;
        return Quickshell.iconPath(name, "application-x-executable");
    }

    FileView {
        id: usageFile
        path: Quickshell.env("HOME") + "/.config/quickshell/launcher-usage.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: usageAdapter
            // id -> { n: times opened, t: epoch ms of the last one }
            property var entries: ({})
        }
    }
}
