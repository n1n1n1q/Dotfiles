pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root
    
    property string userName: Quickshell.env("USER") || "user"
    property string userIconPath: Quickshell.env("HOME") + "/.cache/user-icon"
    
    Component.onCompleted: {
        console.log("System service initialized")
        console.log("User:", userName)
        console.log("User icon path:", userIconPath)
    }
}
