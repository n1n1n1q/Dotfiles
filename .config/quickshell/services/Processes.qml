pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Process list for the system-monitor popout. Polls `ps` only while `active`
// (the card flips it while visible), exposes a client-sortable view and
// kill helpers. Same execDetached("kill") approach as elsewhere in the shell.
Singleton {
    id: root

    // [{ pid, cpu (percent), mem (bytes RSS), name, cmd }]
    property var list: []
    property bool active: false

    property string sortKey: "cpu"      // cpu | mem | name | pid
    property bool sortAsc: false

    function setSort(k) {
        if (sortKey === k)
            sortAsc = !sortAsc;
        else {
            sortKey = k;
            sortAsc = (k === "name");
        }
    }

    // Kernel threads (bracketed args, no RSS) just clutter the list.
    readonly property var sortedList: {
        const a = list.filter(p => p.mem > 0 && p.cmd[0] !== "[");
        const k = sortKey;
        const asc = sortAsc;
        a.sort((x, y) => {
            const c = (k === "name")
                ? String(x.name).localeCompare(String(y.name))
                : (Number(x[k] || 0) - Number(y[k] || 0));
            return asc ? c : -c;
        });
        return a;
    }

    function kill(pid) {
        Quickshell.execDetached(["kill", String(pid)]);
        list = list.filter(p => p.pid !== pid);
        refresh.restart();
    }
    function forceKill(pid) {
        Quickshell.execDetached(["kill", "-9", String(pid)]);
        list = list.filter(p => p.pid !== pid);
        refresh.restart();
    }

    Timer {
        id: poll
        interval: 2500
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    // Quick re-poll shortly after a kill so the row disappears for good.
    Timer {
        id: refresh
        interval: 400
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["bash", "-lc",
            "ps -eo pid=,pcpu=,rss=,comm=,args= --sort=-pcpu | head -n 80"]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                for (const line of text.split("\n")) {
                    const m = line.trim().match(/^(\d+)\s+([\d.]+)\s+(\d+)\s+(\S+)\s*(.*)$/);
                    if (!m) continue;
                    rows.push({
                        pid: parseInt(m[1]),
                        cpu: parseFloat(m[2]),
                        mem: parseInt(m[3]) * 1024,
                        name: m[4],
                        cmd: m[5] || m[4]
                    });
                }
                root.list = rows;
            }
        }
    }
}
