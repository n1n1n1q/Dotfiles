pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Polled system-load snapshot for the bar's left-hand gauges. CPU and RAM come
// from re-read /proc files (end-4's ResourceUsage.qml pattern: a FileView the
// Timer `.reload()`s, then `.text()`). GPU is the max of the always-on AMD iGPU
// (`gpu_busy_percent` sysfs, cheap) and - only while the NVIDIA dGPU is already
// runtime-active, so we never wake it - `nvidia-smi` utilisation.
// All three values are 0..1.
Singleton {
    id: root

    property real cpu: 0
    property real memory: 0
    property real gpu: 0
    property bool gpuAvailable: false

    property var _prevCpu: null

    Timer {
        id: poll
        interval: 1
        running: true
        repeat: true
        onTriggered: {
            fileStat.reload()
            fileMeminfo.reload()

            const stat = fileStat.text()
            const m = stat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (m) {
                const s = m.slice(1).map(Number)
                const total = s.reduce((a, b) => a + b, 0)
                const idle = s[3] + s[4] // idle + iowait
                if (root._prevCpu) {
                    const dt = total - root._prevCpu.total
                    const di = idle - root._prevCpu.idle
                    if (dt > 0)
                        root.cpu = Math.max(0, Math.min(1, 1 - di / dt))
                }
                root._prevCpu = { total, idle }
            }

            const mem = fileMeminfo.text()
            const memTotal = Number(mem.match(/MemTotal:\s*(\d+)/)?.[1] ?? 1)
            const memAvail = Number(mem.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0)
            root.memory = Math.max(0, Math.min(1, 1 - memAvail / memTotal))

            gpuProc.running = true

            interval = 2500 // first tick is immediate, then settle to a real cadence
        }
    }

    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileMeminfo; path: "/proc/meminfo" }

    Process {
        id: gpuProc
        command: ["sh", "-c",
            "amd=$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || echo 0); " +
            "nv=0; " +
            "if [ \"$(cat /sys/class/drm/card0/device/power/runtime_status 2>/dev/null)\" = active ]; then " +
            "nv=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -dc '0-9'); " +
            "fi; " +
            "echo \"${amd:-0} ${nv:-0}\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/).map(Number)
                const amd = isFinite(parts[0]) ? parts[0] : 0
                const nv = isFinite(parts[1]) ? parts[1] : 0
                root.gpu = Math.max(0, Math.min(1, Math.max(amd, nv) / 100))
                root.gpuAvailable = true
            }
        }
    }
}
