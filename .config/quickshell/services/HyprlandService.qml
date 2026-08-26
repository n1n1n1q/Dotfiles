pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: hyprlandService
    
    property var workspaces: [
        { id: 1, active: true, focused: true },
        { id: 2, active: false, focused: false },
        { id: 3, active: false, focused: false },
        { id: 4, active: false, focused: false },
        { id: 5, active: false, focused: false }
    ]
    property var focusedClient: null
    
    // Simplified Hyprland service - you can enhance this with actual Hyprland IPC later
    
    function init() {
        updateWorkspaces()
        updateFocusedClient()
    }
    
    function updateWorkspaces() {
        // This would typically query Hyprland IPC
        // For now, using static data
        console.log("Updating workspaces")
    }
    
    function updateFocusedClient() {
        // This would typically query Hyprland IPC
        console.log("Updating focused client")
    }
    
    function switchToWorkspace(id) {
        console.log("Switching to workspace:", id)
        // This would dispatch to Hyprland: hyprctl dispatch workspace ${id}
        
        // Update local state for demo
        var newWorkspaces = []
        for (var i = 0; i < workspaces.length; i++) {
            var ws = workspaces[i]
            newWorkspaces.push({
                id: ws.id,
                active: ws.id === id,
                focused: ws.id === id
            })
        }
        workspaces = newWorkspaces
    }
    
    function moveToWorkspace(id) {
        console.log("Moving to workspace:", id)
        // This would dispatch to Hyprland: hyprctl dispatch movetoworkspace ${id}
    }
}
