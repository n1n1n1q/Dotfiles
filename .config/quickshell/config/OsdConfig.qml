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

    // The slider style is a single global now — Settings › Appearance ›
    // Slider style, stored on `Appearance`. This alias is kept so the OSD and
    // the old Notifications page still compile.
    readonly property string sliderStyle: Appearance.sliderStyle

    readonly property var defaults: ({ "sliderStyle": "progress" })

    function setSliderStyle(style) { Appearance.setSliderStyle(style); }

    function reset() { Appearance.setSliderStyle("progress"); }

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
