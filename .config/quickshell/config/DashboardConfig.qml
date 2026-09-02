pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Data-driven dashboard layout — the panel that drops out of the window title
// on the left of the bar. Two ordered lists plus a notification block:
//
//   toggles: [ { "id": "wifi", "size": "large" }, ... ]   quick-settings grid
//   sliders: [ { "id": "volume", "style": "progress" }, ... ]
//   notifications: { "corner", "grouping", "closeDelay" }
//
// A toggle is one cell of a `columns`-wide grid; a "large" one spans two and
// gets a label beside its glyph. Persisted as JSON at
// ~/.config/quickshell/dashboard.json — hand-editable, and written back by the
// in-panel editor (Settings > Dashboard, or `qs ipc call dashboard edit`).
Singleton {
    id: root

    readonly property var toggles: adapter.toggles
    readonly property var sliders: adapter.sliders
    property bool ready: false

    // The quick-settings grid is this many cells wide; a "large" tile eats two.
    readonly property int columns: 5

    // --- notifications ---------------------------------------------------
    readonly property var defaultNotifications: ({
        "corner": "top-right",   // top-right | top-left | bottom-right | bottom-left
        "grouping": "off",       // off | source
        "closeDelay": 350        // ms of hover before the close button fades in
    })
    readonly property string notifCorner: adapter.notifications?.corner ?? "top-right"
    readonly property string notifGrouping: adapter.notifications?.grouping ?? "off"
    readonly property int notifCloseDelay: adapter.notifications?.closeDelay ?? 350
    readonly property bool notifGrouped: notifGrouping === "source"
    readonly property bool notifAtTop: notifCorner.indexOf("top") === 0
    readonly property bool notifAtLeft: notifCorner.indexOf("left") > 0

    function setNotif(key, val) {
        const n = JSON.parse(JSON.stringify(adapter.notifications ?? defaultNotifications));
        n[key] = val;
        adapter.notifications = n;
    }

    // --- catalogues (metadata for the editor + the settings page) ---------
    // `size` / `style` are what a freshly-dropped entry starts out as.
    readonly property var toggleCatalogue: [
        { id: "wifi",       name: "Wi‑Fi",       icon: "󰖩", size: "large", desc: "Toggle the radio; the wide tile names the network" },
        { id: "bluetooth",  name: "Bluetooth",   icon: "󰂯", size: "large", desc: "Toggle the adapter; the wide tile names the device" },
        { id: "dnd",        name: "Do Not Disturb", icon: "󰂛", size: "small", desc: "Silence popups — the centre still records them" },
        { id: "mute",       name: "Mute output", icon: "󰖁", size: "small", desc: "Mute the default sink" },
        { id: "micMute",    name: "Mute mic",    icon: "󰍭", size: "small", desc: "Mute the default source" },
        { id: "screenshot", name: "Screenshot",  icon: "󰄀", size: "small", desc: "niri's interactive screenshot UI" },
        { id: "caffeine",   name: "Keep awake",  icon: "󰅶", size: "small", desc: "Hold off sleep, screen-blank and idle-lock" },
        { id: "lock",       name: "Lock",        icon: "󰌾", size: "small", desc: "Lock the session" },
        { id: "record",     name: "Record",      icon: "󰑊", size: "small", desc: "Start wf-recorder" },
        { id: "wallpaper",  name: "Wallpaper",   icon: "󰸉", size: "small", desc: "Step to the next wallpaper" },
        { id: "settings",   name: "Settings",    icon: "󰒓", size: "small", desc: "Open this settings window" },
        { id: "launcher",   name: "Launcher",    icon: "󱓞", size: "small", desc: "Open the app launcher" }
    ]

    // How a slider row draws itself, in the order clicking a placed row steps
    // through them. The three flags are the whole of what a style *is* —
    // widgets/LevelBar draws from them, and a row or an OSD card reads
    // `iconInside` to know whether the bar carries the glyph and its own icon
    // column would only say it twice. An entry with no flag is the plain
    // filled capsule.
    //
    //   handle      a knob riding a thin track, instead of a filled capsule
    //   split       the level and what's left of it as two capsules, apart
    //   iconInside  the glyph moves into the bar's leading end
    readonly property var sliderStyles: [
        { value: "progress",     label: "Progress bar", desc: "A chunky filled capsule, glyph beside it" },
        { value: "slider",       label: "Slider",       desc: "A handle on a thin track, glyph beside it", handle: true },
        { value: "inline",       label: "Icon inside",  desc: "The capsule again, with the glyph inside its leading end", iconInside: true },
        { value: "split",        label: "Split",        desc: "A slim pair — the level, a gap, then what's left of it dimmed", split: true },
        { value: "split-inline", label: "Split + icon", desc: "The split pair, taller, with the glyph inside the level's leading end", split: true, iconInside: true }
    ]

    function sliderStyleEntry(style) {
        return sliderStyles.find(s => s.value === style) ?? sliderStyles[0];
    }
    function sliderStyleLabel(style) { return sliderStyleEntry(style).label; }

    readonly property var sliderCatalogue: [
        { id: "volume",     name: "Volume",     icon: "󰕾", desc: "Output level — right-click for the device list", menu: true },
        { id: "microphone", name: "Microphone", icon: "󰍬", desc: "Input level — right-click for the device list",  menu: true },
        { id: "brightness", name: "Brightness", icon: "󰃟", desc: "Display backlight",                              menu: false }
    ]

    function toggleEntry(id) {
        return toggleCatalogue.find(t => t.id === id)
            ?? ({ id: id, name: id, icon: "󰋙", size: "small", desc: "" });
    }
    function sliderEntry(id) {
        return sliderCatalogue.find(s => s.id === id)
            ?? ({ id: id, name: id, icon: "󰋙", desc: "", menu: false });
    }
    function toggleName(id) { return toggleEntry(id).name; }
    function toggleIcon(id) { return toggleEntry(id).icon; }
    function sliderName(id) { return sliderEntry(id).name; }
    function sliderIcon(id) { return sliderEntry(id).icon; }

    // Each id may sit in the panel once, so the pool is "everything not placed".
    function _placed(list) { return (list ?? []).map(e => e.id); }
    readonly property var availableToggles:
        toggleCatalogue.filter(t => _placed(toggles).indexOf(t.id) === -1)
    readonly property var availableSliders:
        sliderCatalogue.filter(s => _placed(sliders).indexOf(s.id) === -1)

    function hasToggle(id) { return _placed(toggles).indexOf(id) !== -1; }
    function hasSlider(id) { return _placed(sliders).indexOf(id) !== -1; }

    // --- defaults ---------------------------------------------------------
    readonly property var defaults: ({
        "toggles": [
            { "id": "wifi",       "size": "large" },
            { "id": "bluetooth",  "size": "large" },
            { "id": "dnd",        "size": "small" },
            { "id": "mute",       "size": "small" },
            { "id": "micMute",    "size": "small" },
            { "id": "screenshot", "size": "small" },
            { "id": "caffeine",   "size": "small" },
            { "id": "lock",       "size": "small" },
            { "id": "settings",   "size": "small" }
        ],
        "sliders": [
            { "id": "volume",     "style": "progress" },
            { "id": "microphone", "style": "progress" },
            { "id": "brightness", "style": "progress" }
        ]
    })

    // The two halves are separately resettable because they are configured on
    // separate settings pages — tiles and sliders on Dashboard, the popup block
    // on Notifications.
    function resetLayout() {
        adapter.toggles = JSON.parse(JSON.stringify(defaults.toggles));
        adapter.sliders = JSON.parse(JSON.stringify(defaults.sliders));
    }

    function resetNotifications() {
        adapter.notifications = JSON.parse(JSON.stringify(defaultNotifications));
    }

    function reset() {
        resetLayout();
        resetNotifications();
    }

    // --- preset slice -----------------------------------------------------
    function snapshot() {
        return JSON.parse(JSON.stringify({
            "toggles": adapter.toggles,
            "sliders": adapter.sliders,
            "notifications": adapter.notifications ?? defaultNotifications
        }));
    }

    function applySnapshot(o) {
        if (!o) return;
        if (editMode) commitEdit();
        if (o.toggles) adapter.toggles = JSON.parse(JSON.stringify(o.toggles));
        if (o.sliders) adapter.sliders = JSON.parse(JSON.stringify(o.sliders));
        if (o.notifications)
            adapter.notifications = Object.assign(
                JSON.parse(JSON.stringify(defaultNotifications)), o.notifications);
    }

    // --- live "edit in the panel" mode -------------------------------------
    // Same shape as BarConfig's: the dashboard pins itself open, tiles jiggle,
    // hold one and drag it onto an insert marker. Enter commits, Esc cancels.
    property bool editMode: false
    property var _snap: null

    // null | { kind: "toggles"|"sliders", mode: "new"|"move", id, index }
    property var grab: null
    readonly property bool grabbing: grab !== null

    function beginEdit() {
        _snap = JSON.stringify({ t: adapter.toggles, s: adapter.sliders });
        grab = null;
        editMode = true;
    }
    function commitEdit() {
        _snap = null;
        grab = null;
        editMode = false;
    }
    function cancelEdit() {
        if (_snap !== null) {
            const s = JSON.parse(_snap);
            adapter.toggles = s.t;
            adapter.sliders = s.s;
            _snap = null;
        }
        grab = null;
        editMode = false;
    }

    function pickNew(kind, id) { grab = { kind: kind, mode: "new", id: id, index: -1 }; }
    function pickPlaced(kind, index) {
        const e = (adapter[kind] ?? [])[index];
        if (!e) return;
        grab = { kind: kind, mode: "move", id: e.id, index: index };
    }
    function cancelGrab() { grab = null; }

    function _fresh(kind, id) {
        return kind === "toggles"
            ? ({ id: id, size: toggleEntry(id).size ?? "small" })
            : ({ id: id, style: "progress" });
    }

    // Drop the held entry at `index` in its own list (index === length appends).
    function dropAt(kind, index) {
        const g = grab;
        grab = null;
        if (!g || g.kind !== kind) return;
        const a = _clone(kind);
        if (g.mode === "new") {
            if (a.some(e => e.id === g.id)) return;
            a.splice(Math.max(0, Math.min(index, a.length)), 0, _fresh(kind, g.id));
        } else {
            const it = a.splice(g.index, 1)[0];
            if (it === undefined) return;
            let j = g.index < index ? index - 1 : index;
            a.splice(Math.max(0, Math.min(j, a.length)), 0, it);
        }
        _commit(kind, a);
    }

    // Dropped back on the pool dock — a placed entry leaves the panel, a fresh
    // one just never arrives.
    function dropRemove() {
        const g = grab;
        grab = null;
        if (!g || g.mode !== "move") return;
        removeAt(g.kind, g.index);
    }

    // --- editing helpers (clone -> mutate -> reassign, so the file autosaves) -
    function _clone(kind) { return JSON.parse(JSON.stringify(adapter[kind] ?? [])); }
    function _commit(kind, a) { adapter[kind] = a; }

    function addAt(kind, index, id) {
        const a = _clone(kind);
        if (a.some(e => e.id === id)) return;
        a.splice(Math.max(0, Math.min(index, a.length)), 0, _fresh(kind, id));
        _commit(kind, a);
    }
    function add(kind, id) { addAt(kind, (adapter[kind] ?? []).length, id); }
    function removeAt(kind, index) {
        const a = _clone(kind);
        if (index < 0 || index >= a.length) return;
        a.splice(index, 1);
        _commit(kind, a);
    }
    function moveAt(kind, index, dir) {
        const a = _clone(kind);
        const j = index + dir;
        if (j < 0 || j >= a.length) return;
        const t = a[index];
        a[index] = a[j];
        a[j] = t;
        _commit(kind, a);
    }

    // A tile is one cell wide, or two with its name beside the glyph.
    function toggleSizeOf(index) { return (toggles[index]?.size) ?? "small"; }
    function setToggleSize(index, size) {
        const a = _clone("toggles");
        if (!a[index]) return;
        a[index].size = size;
        _commit("toggles", a);
    }
    function cycleToggleSize(index) {
        setToggleSize(index, toggleSizeOf(index) === "large" ? "small" : "large");
    }

    // One of `sliderStyles`; anything else on disk reads as the default.
    function sliderStyleOf(index) {
        return sliderStyleEntry(sliders[index]?.style).value;
    }
    function setSliderStyle(index, style) {
        const a = _clone("sliders");
        if (!a[index]) return;
        a[index].style = sliderStyleEntry(style).value;
        _commit("sliders", a);
    }
    function cycleSliderStyle(index) {
        const i = sliderStyles.findIndex(s => s.value === sliderStyleOf(index));
        setSliderStyle(index, sliderStyles[(i + 1) % sliderStyles.length].value);
    }

    // There is one panel per screen, so opening it goes through these signals;
    // every live DashboardWindow listens and takes the ones addressed to it.
    // An empty `screenName` means "every screen".
    signal showRequested(string screenName)
    signal hideRequested(string screenName)
    signal toggleRequested(string screenName)

    function requestShow(s) { showRequested(s ?? ""); }
    function requestHide(s) { hideRequested(s ?? ""); }
    function requestToggle(s) { toggleRequested(s ?? ""); }

    IpcHandler {
        target: "dashboard"
        // `open`, not `show`: `show` is one of `qs ipc`'s own subcommands and
        // the CLI swallows it before it reaches the handler.
        function open(): void { root.requestShow(""); }
        function hide(): void { root.requestHide(""); }
        function toggle(): void { root.requestToggle(""); }
        function edit(): void { root.beginEdit(); }
        function done(): void { root.commitEdit(); }
        function cancel(): void { root.cancelEdit(); }
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/dashboard.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.ready = true
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.reset();
                writeAdapter();
                root.ready = true;
            }
        }

        JsonAdapter {
            id: adapter
            property var toggles: root.defaults.toggles
            property var sliders: root.defaults.sliders
            property var notifications: root.defaultNotifications
        }
    }
}
