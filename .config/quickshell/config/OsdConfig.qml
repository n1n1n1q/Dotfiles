pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The transient pill that drops under the bar when volume, brightness or the
// keyboard layout changes (modules/osd). How it draws its level:
//
//   { "sliderStyle": "progress" }
//
// Persisted as JSON at ~/.config/quickshell/osd.json — hand-editable, and
// written back by Settings > Notifications > On-screen display.
Singleton {
    id: root

    // One of DashboardConfig.sliderStyles — the pill wears exactly what the
    // panel's own slider rows do, so the two can be made to match. Read and
    // write both go through the catalogue, so a typo in the JSON leaves a
    // drawable pill rather than a bare track.
    readonly property string sliderStyle:
        DashboardConfig.sliderStyleEntry(adapter.sliderStyle).value

    readonly property var defaults: ({ "sliderStyle": "progress" })

    function setSliderStyle(style) {
        adapter.sliderStyle = DashboardConfig.sliderStyleEntry(style).value;
    }

    function reset() { adapter.sliderStyle = root.defaults.sliderStyle; }

    // --- preset slice -------------------------------------------------------
    function snapshot() {
        return { "sliderStyle": adapter.sliderStyle };
    }

    function applySnapshot(o) {
        if (!o) return;
        if (o.sliderStyle !== undefined) root.setSliderStyle(o.sliderStyle);
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/osd.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter(); }

        JsonAdapter {
            id: adapter
            property string sliderStyle: "progress"
        }
    }
}
