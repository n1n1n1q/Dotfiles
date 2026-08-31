pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Wi-Fi via nmcli. Keeps a scanned list of access points (grouped by SSID),
// tracks the active one, and drives connect / disconnect / forget. Connect
// surfaces a "needs a password" / "check your login" state per-SSID so the UI
// can prompt inline. Ideas taken from end-4's dots-hyprland Network.qml.
Singleton {
    id: root

    // --- state -------------------------------------------------------------
    property bool enabled: true

    // Scanned APs, active pinned first then known, then by signal. Each entry:
    //   { ssid, signal (0..100), security, secure, enterprise, active, known }
    property var networks: []
    readonly property var activeNetwork: networks.find(n => n.active) ?? null
    readonly property bool connected: activeNetwork !== null
    readonly property string ssid: activeNetwork?.ssid ?? ""
    readonly property int strength: activeNetwork?.signal ?? 0
    readonly property bool scanning: rescanProc.running

    // Per-SSID connection feedback.
    property string busySsid: ""
    readonly property bool connecting: busySsid.length > 0
    property string errorSsid: ""
    property string errorText: ""

    property var _saved: []

    readonly property string icon: {
        if (!enabled) return "󰖪"            // wifi-off
        if (!connected) return "󰤫"          // wifi-strength-off-outline
        if (strength > 75) return "󰤨"
        if (strength > 50) return "󰤥"
        if (strength > 25) return "󰤢"
        return "󰤟"
    }

    // Every glyph `icon` and `signalIcon` can return, so a cell drawing one
    // can be sized from the set rather than from whichever state is showing
    // — the glyphs are not all the same width. See GlyphIcon.
    readonly property var iconStates: ["󰖪", "󰤫", "󰤨", "󰤥", "󰤢", "󰤟", "󰤯"]

    function signalIcon(sig) {
        if (sig > 75) return "󰤨"
        if (sig > 50) return "󰤥"
        if (sig > 25) return "󰤢"
        if (sig > 0)  return "󰤟"
        return "󰤯"
    }

    // --- actions ---------------------------------------------------------------
    function setEnabled(on) {
        radioProc.exec(["nmcli", "radio", "wifi", on ? "on" : "off"]);
    }
    function toggleWifi() {
        setEnabled(!enabled);
    }
    function scan() {
        if (enabled)
            rescanProc.running = true;
    }
    function rescan() {
        scan();
    }

    function _begin(s) {
        busySsid = s;
        errorSsid = "";
        errorText = "";
    }
    function _fail(s, msg) {
        busySsid = "";
        errorSsid = s;
        errorText = msg;
    }
    function clearError() {
        errorSsid = "";
        errorText = "";
    }

    function _env(extra) {
        let e = { "LANG": "C", "LC_ALL": "C" };
        for (const k in extra)
            e[k] = extra[k];
        return e;
    }

    // Open network, or one we already have a saved profile for (nmcli reuses
    // the stored secrets).
    function connect(ssid) {
        _begin(ssid);
        cxnProc.exec({
            "environment": _env({ "SSID": ssid }),
            "command": ["bash", "-c", 'nmcli dev wifi connect "$SSID"']
        });
    }

    function connectWithPassword(ssid, password) {
        _begin(ssid);
        cxnProc.exec({
            "environment": _env({ "SSID": ssid, "PW": password }),
            "command": ["bash", "-c", 'nmcli dev wifi connect "$SSID" password "$PW"']
        });
    }

    // WPA/WPA2-Enterprise (802.1X) with PEAP/MSCHAPv2 — the common corporate /
    // eduroam-style setup.
    function connectEnterprise(ssid, username, password) {
        _begin(ssid);
        cxnProc.exec({
            "environment": _env({ "SSID": ssid, "IDENT": username, "PW": password }),
            "command": ["bash", "-c",
                'nmcli con delete "$SSID" >/dev/null 2>&1; ' +
                'nmcli con add type wifi con-name "$SSID" ssid "$SSID" ' +
                'wifi-sec.key-mgmt wpa-eap ' +
                '802-1x.eap peap 802-1x.phase2-auth mschapv2 ' +
                '802-1x.identity "$IDENT" 802-1x.password "$PW" && ' +
                'nmcli con up "$SSID"']
        });
    }

    function disconnectFrom(name) {
        const s = name || root.ssid;
        if (s.length > 0)
            disconnectProc.exec(["nmcli", "con", "down", s]);
    }
    function forget(name) {
        if (name && name.length > 0)
            forgetProc.exec(["nmcli", "con", "delete", name]);
    }

    // --- refresh -------------------------------------------------------------
    function refresh() {
        radioQuery.running = true;
        savedProc.running = true;
    }

    Process {
        id: monitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: refreshDebounce.restart()
        }
    }
    Timer {
        id: refreshDebounce
        interval: 300
        onTriggered: root.refresh()
    }
    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: radioQuery
        command: ["nmcli", "radio", "wifi"]
        environment: ({ "LANG": "C", "LC_ALL": "C" })
        stdout: StdioCollector {
            onStreamFinished: root.enabled = text.trim() === "enabled"
        }
    }

    // Saved wifi profile names — feeds each network's `known` flag. Chained
    // before the AP list so `known` is right on the same cycle.
    Process {
        id: savedProc
        command: ["nmcli", "-g", "NAME,TYPE", "con", "show"]
        environment: ({ "LANG": "C", "LC_ALL": "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                root._saved = text.trim().split("\n")
                    .map(l => l.split(":"))
                    .filter(p => p[1] === "802-11-wireless")
                    .map(p => p[0]);
            }
        }
        onExited: listProc.running = true
    }

    Process {
        id: listProc
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,SSID,SECURITY", "dev", "wifi"]
        environment: ({ "LANG": "C", "LC_ALL": "C" })
        stdout: StdioCollector {
            onStreamFinished: root._parseList(text)
        }
    }

    function _parseList(text) {
        const PH = "\u0001";
        const phRe = new RegExp(PH, "g");
        const rows = text.trim().split("\n").filter(l => l.length > 0).map(line => {
            const f = line.replace(/\\:/g, PH).split(":");
            const ssid = (f[2] || "").replace(phRe, ":");
            const sec = (f[3] || "").replace(phRe, ":").trim();
            return {
                "active": f[0] === "yes",
                "signal": parseInt(f[1]) || 0,
                "ssid": ssid,
                "security": sec,
                "secure": sec.length > 0 && sec !== "--",
                "enterprise": sec.indexOf("802.1X") !== -1,
                "known": root._saved.indexOf(ssid) !== -1
            };
        }).filter(n => n.ssid.length > 0);

        const map = {};
        for (const n of rows) {
            const e = map[n.ssid];
            if (!e || (n.active && !e.active) || (!e.active && n.signal > e.signal))
                map[n.ssid] = n;
        }
        const list = Object.keys(map).map(k => map[k]);
        list.sort((a, b) => (b.active - a.active) || (b.known - a.known) || (b.signal - a.signal));
        root.networks = list;

        if (root.busySsid.length > 0 && map[root.busySsid] && map[root.busySsid].active) {
            root.busySsid = "";
            root.errorSsid = "";
            root.errorText = "";
        }
    }

    Process {
        id: radioProc
        onExited: root.refresh()
    }
    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        environment: ({ "LANG": "C", "LC_ALL": "C" })
        stdout: StdioCollector {
            onStreamFinished: root._parseList(text)
        }
        onExited: root.refresh()
    }

    Process {
        id: cxnProc
        property string lastErr: ""
        stdout: SplitParser {
            onRead: refreshDebounce.restart()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) cxnProc.lastErr = text.trim()
        }
        onExited: code => {
            const s = root.busySsid;
            if (code === 0) {
                root.busySsid = "";
                root.errorSsid = "";
                root.errorText = "";
            } else {
                let msg = cxnProc.lastErr;
                if (msg.indexOf("Secrets were required") !== -1 || msg.indexOf("no secrets") !== -1)
                    msg = "Password required";
                else if (msg.indexOf("802-1x") !== -1 || msg.indexOf("802.1X") !== -1)
                    msg = "Check your username and password";
                else
                    msg = (msg.split("\n")[0] || "").replace(/^Error:\s*/, "") || "Couldn't connect";
                root._fail(s, msg);
            }
            cxnProc.lastErr = "";
            root.refresh();
        }
    }
    Process {
        id: disconnectProc
        onExited: root.refresh()
    }
    Process {
        id: forgetProc
        onExited: root.refresh()
    }

    Component.onCompleted: {
        refresh();
        if (enabled)
            rescanProc.running = true;
    }
}
