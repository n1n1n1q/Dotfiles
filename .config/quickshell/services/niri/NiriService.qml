pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Bridges the niri compositor's IPC (a newline-delimited JSON protocol over
// $NIRI_SOCKET, see `niri msg --help` / https://github.com/niri-wm/niri/wiki/IPC)
// into reactive QML state. There is no first-party `Quickshell.Niri` module
// (unlike `Quickshell.Hyprland`), so this talks to the socket directly rather
// than pulling in a separate compiled Qt plugin.
//
// Strategy: keep one persistent socket subscribed to niri's event stream just
// to learn *that* something changed, then re-fetch the authoritative state
// with `niri msg -j workspaces`/`windows`. That's a little less clever than
// hand-parsing every event payload, but it's immune to this file drifting out
// of sync with niri's exact event schema across versions.
Singleton {
    id: root

    property bool available: false
    property var workspaces: [] // raw objects from `niri msg -j workspaces`
    property var windows: [] // raw objects from `niri msg -j windowSs`

    // Configured keyboard layouts + which one is active, from
    // `niri msg -j keyboard-layouts`. Re-fetched on every niri event (same
    // as workspaces/windows), so `keyboardLayoutIdx` tracks Mod+Space etc.
    property var keyboardLayoutNames: []
    property int keyboardLayoutIdx: 0
    readonly property string keyboardLayoutName: keyboardLayoutNames[keyboardLayoutIdx] ?? ""

    readonly property var focusedWindow: windows.find(w => w.is_focused) ?? null
    readonly property var focusedWorkspace: workspaces.find(w => w.is_focused) ?? null

    // The window the bar's title block shows, following end-4's ActiveWindow
    // fallback chain. Workspace `is_focused` is reliable on this build, so
    // trust the focused workspace's own `active_window_id` first; then window
    // `is_focused` (often all-false here); then the biggest window sitting on
    // the focused workspace; else nothing (empty workspace).
    readonly property var activeWindow: {
        const ws = focusedWorkspace
        if (ws && ws.active_window_id !== null && ws.active_window_id !== undefined) {
            const w = windows.find(x => x.id === ws.active_window_id)
            if (w) return w
        }
        const focused = windows.find(w => w.is_focused)
        if (focused) return focused
        if (ws) return biggestWindowForWorkspace(ws.id)
        return null
    }
    readonly property string activeWindowTitle: activeWindow?.title ?? ""
    readonly property string activeWindowAppId: activeWindow?.app_id ?? ""

    function biggestWindowForWorkspace(workspaceId) {
        const area = w => {
            const s = w.layout?.tile_size ?? w.layout?.window_size ?? [0, 0]
            return (s[0] ?? 0) * (s[1] ?? 0)
        }
        return windows
            .filter(w => w.workspace_id === workspaceId)
            .sort((a, b) => area(b) - area(a))[0] ?? null
    }

    function workspacesForOutput(outputName) {
        return workspaces
            .filter(w => w.output === outputName)
            .sort((a, b) => a.idx - b.idx)
    }

    function windowCountForWorkspace(workspaceId) {
        return windows.filter(w => w.workspace_id === workspaceId).length
    }

    function isWorkspaceOccupied(workspaceId) {
        return windowCountForWorkspace(workspaceId) > 0
    }

    // `idx` is the workspace's position on its (focused) output, matching
    // niri's own `focus-workspace`/keybind semantics - not a stable global id.
    function focusWorkspace(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(idx)])
    }

    function moveWindowToWorkspace(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "move-window-to-workspace", String(idx)])
    }

    function focusWindow(id) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(id)])
    }

    // Best-effort "focus the app this notification came from": match `hint`
    // (a notification's desktopEntry, falling back to its appName) against
    // window `app_id`s case-insensitively, and focus the most recently focused
    // match. Returns whether anything matched.
    function focusApp(hint) {
        if (!hint)
            return false
        const h = String(hint).toLowerCase().replace(/\.desktop$/, "")
        const matches = windows.filter(w => {
            const a = (w.app_id ?? "").toLowerCase()
            return a.length > 0 && (a === h || a.includes(h) || h.includes(a))
        })
        if (matches.length === 0)
            return false
        matches.sort((a, b) => (b.focus_timestamp?.secs ?? 0) - (a.focus_timestamp?.secs ?? 0))
        focusWindow(matches[0].id)
        return true
    }

    // Opens niri's built-in interactive screenshot UI - no grim/slurp/grimblast needed.
    function screenshot() {
        Quickshell.execDetached(["niri", "msg", "action", "screenshot"])
    }

    function screenshotScreen() {
        Quickshell.execDetached(["niri", "msg", "action", "screenshot-screen"])
    }

    property Timer _refreshDebounce: Timer {
        interval: 40
        onTriggered: {
            workspacesProc.running = true
            windowsProc.running = true
            keyboardLayoutsProc.running = true
        }
    }

    function _scheduleRefresh() {
        _refreshDebounce.restart()
    }

    Process {
        id: workspacesProc
        command: ["niri", "msg", "-j", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.workspaces = JSON.parse(text)
                } catch (e) {
                    console.warn("NiriService: failed to parse `niri msg -j workspaces`:", e)
                }
            }
        }
    }

    Process {
        id: windowsProc
        command: ["niri", "msg", "-j", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.windows = JSON.parse(text)
                } catch (e) {
                    console.warn("NiriService: failed to parse `niri msg -j windows`:", e)
                }
            }
        }
    }

    Process {
        id: keyboardLayoutsProc
        command: ["niri", "msg", "-j", "keyboard-layouts"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text)
                    root.keyboardLayoutNames = d.names ?? []
                    root.keyboardLayoutIdx = d.current_idx ?? 0
                } catch (e) {
                    console.warn("NiriService: failed to parse `niri msg -j keyboard-layouts`:", e)
                }
            }
        }
    }

    Socket {
        id: eventSocket
        path: Quickshell.env("NIRI_SOCKET") ?? ""
        connected: path !== ""

        parser: SplitParser {
            onRead: data => {
                // The first line is the ack for our "EventStream" request;
                // every line after that is a compositor event. We don't care
                // which one - any line means "go re-sync".
                root._scheduleRefresh()
            }
        }

        onConnectedChanged: {
            if (connected) {
                root.available = true
                write("\"EventStream\"\n")
                flush()
                root._scheduleRefresh()
            } else {
                root.available = false
                reconnectTimer.restart()
            }
        }

        onError: error => {
            console.warn("NiriService: socket error:", error)
            connected = false
        }
    }

    Timer {
        id: reconnectTimer
        interval: 2000
        onTriggered: {
            if (eventSocket.path !== "") eventSocket.connected = true
        }
    }

    Component.onCompleted: _scheduleRefresh()
}
