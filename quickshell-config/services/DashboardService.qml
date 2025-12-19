pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: dashboardService
    
    property bool visible: false
    
    function show() {
        visible = true
    }
    
    function hide() {
        visible = false
    }
    
    function toggle() {
        visible = !visible
    }
}
