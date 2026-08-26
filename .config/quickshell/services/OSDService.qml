pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: osdService
    
    property bool visible: false
    property string icon: ""
    property string title: ""
    property int value: 0
    
    function showVolume(vol) {
        icon = vol > 0 ? "\udb81\udd7e" : "\udb81\udd81"
        title = "Volume"
        value = vol
        show()
    }
    
    function showBrightness(brightness) {
        icon = "\uf185"
        title = "Brightness"
        value = brightness
        show()
    }
    
    function show() {
        visible = true
    }
    
    function hide() {
        visible = false
    }
}
