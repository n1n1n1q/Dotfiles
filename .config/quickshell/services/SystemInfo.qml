pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Richer system telemetry for the system-monitor popout (temps, network
// throughput + session totals, disk usage). SysResources stays the lean feed
// for the bar gauges; this only polls while `active` (the card flips it).
Singleton {
    id: root

    property bool active: false

    property real cpuTemp: 0      // °C
    property real gpuTemp: 0      // °C
    property real netDown: 0      // bytes/s
    property real netUp: 0        // bytes/s
    property real netDownTotal: 0 // bytes since shell start
    property real netUpTotal: 0
    property real diskUsed: 0     // bytes, "/"
    property real diskTotal: 0

    property var _prevNet: null

    Timer {
        interval: 3000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            tempProc.running = true;
            diskProc.running = true;
            netFile.reload();
            root._readNet();
        }
    }

    FileView { id: netFile; path: "/proc/net/dev" }

    function _readNet() {
        const text = netFile.text();
        if (!text || text.length === 0)
            return;
        let rx = 0, tx = 0;
        for (const line of text.split("\n")) {
            const m = line.trim().match(/^([\w-]+):\s*(.+)$/);
            if (!m || m[1] === "lo")
                continue;
            const f = m[2].trim().split(/\s+/).map(Number);
            if (f.length < 9)
                continue;
            rx += f[0];
            tx += f[8];
        }
        const now = Date.now();
        if (root._prevNet) {
            const dt = (now - root._prevNet.t) / 1000;
            if (dt > 0) {
                root.netDown = Math.max(0, (rx - root._prevNet.rx) / dt);
                root.netUp = Math.max(0, (tx - root._prevNet.tx) / dt);
            }
            root.netDownTotal += Math.max(0, rx - root._prevNet.rx);
            root.netUpTotal += Math.max(0, tx - root._prevNet.tx);
        }
        root._prevNet = { t: now, rx: rx, tx: tx };
    }

    Process {
        id: tempProc
        command: ["bash", "-lc",
            'for h in /sys/class/hwmon/hwmon*; do ' +
            'n=$(cat "$h/name" 2>/dev/null); ' +
            'for t in "$h"/temp*_input; do [ -e "$t" ] || continue; ' +
            'l=$(cat "${t%_input}_label" 2>/dev/null); v=$(cat "$t" 2>/dev/null); ' +
            'echo "$n|$l|$v"; done; done']
        stdout: StdioCollector {
            onStreamFinished: {
                let cpu = 0, gpu = 0;
                for (const line of text.split("\n")) {
                    const p = line.split("|");
                    if (p.length < 3) continue;
                    const name = (p[0] || "").toLowerCase();
                    const label = (p[1] || "").toLowerCase();
                    const val = Number(p[2]) / 1000;
                    if (!isFinite(val) || val <= 0) continue;
                    if (/k10temp|coretemp|zenpower|cpu/.test(name)
                        && /tctl|tccd|package|core 0|^$/.test(label))
                        cpu = cpu || val;
                    if (/amdgpu|nouveau|nvidia|radeon/.test(name)
                        && /edge|junction|gpu|^$/.test(label))
                        gpu = gpu || val;
                }
                if (cpu > 0) root.cpuTemp = cpu;
                if (gpu > 0) root.gpuTemp = gpu;
            }
        }
    }

    Process {
        id: diskProc
        command: ["bash", "-lc", "df -B1 --output=used,size / | tail -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(/\s+/).map(Number);
                if (f.length >= 2 && isFinite(f[0]) && isFinite(f[1])) {
                    root.diskUsed = f[0];
                    root.diskTotal = f[1];
                }
            }
        }
    }
}
