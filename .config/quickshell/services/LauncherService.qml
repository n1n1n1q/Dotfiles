pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: launcherService
    
    property bool visible: false
    property var applications: []
    property var allApplications: []
    
    Component.onCompleted: loadApplications()
    
    function loadApplications() {
        // This is a simplified implementation
        // In a real implementation, you'd parse .desktop files
        allApplications = [
            { name: "Firefox", exec: "firefox", icon: "\uf269" },
            { name: "Terminal", exec: "kitty", icon: "\uf120" },
            { name: "File Manager", exec: "thunar", icon: "\uf07b" },
            { name: "Text Editor", exec: "code", icon: "\uf044" },
            { name: "Settings", exec: "gnome-control-center", icon: "\ueb52" }
        ]
        applications = allApplications
    }
    
    function show() {
        visible = true
    }
    
    function hide() {
        visible = false
    }
    
    function toggle() {
        visible = !visible
    }
    
    function search(query) {
        if (query === "") {
            applications = allApplications
        } else {
            applications = allApplications.filter(app => 
                app.name.toLowerCase().includes(query.toLowerCase())
            )
        }
    }
    
    function launch(command) {
        const process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["${command}"]
                running: true
            }
        `, launcherService)
    }
}
