pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root
    
    readonly property date date: clock.date
    readonly property string timeString: Qt.formatDateTime(date, "hh:mm")
    readonly property string dateString: Qt.formatDateTime(date, "MMM dd")
    
    function format(fmt) {
        return Qt.formatDateTime(clock.date, fmt);
    }
    
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
