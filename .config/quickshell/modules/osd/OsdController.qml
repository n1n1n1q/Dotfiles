pragma Singleton

import QtQuick
import Quickshell

// Global OSD inhibit. Surfaces that already show the volume / brightness
// level themselves - the dashboard's sliders - hold an inhibit while they're
// open, so dragging one doesn't also drop the OSD pill under the bar: the
// level is right there under the cursor, and the pill is pure noise.
//
// Counted rather than a plain flag so overlapping holders can't clobber each
// other; every inhibit() must be paired with a release().
Singleton {
    id: root

    property int inhibitCount: 0
    readonly property bool inhibited: inhibitCount > 0

    function inhibit(): void {
        inhibitCount++;
    }

    function release(): void {
        if (inhibitCount > 0)
            inhibitCount--;
    }
}
