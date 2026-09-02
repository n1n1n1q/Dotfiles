import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services.niri
import qs.modules.settings

// Every niri keybind, grouped by what it drives — the shell's own widget
// actions first, then apps, media, and niri's window management. A row's keys
// and command are editable, it can be disabled (kept but commented out) or
// removed outright; the widget actions can't be removed, only set to a key or
// to nothing. Every change is validated by niri and rolled back if it fails.
SettingsPage {
    id: page
    heading: "Keybinds"
    icon: "󰥻"
    blurb: "Keyboard shortcuts, from niri's binds block."

    property string query: ""

    function _match(b) {
        if (query.length === 0) return true;
        const q = query.toLowerCase();
        return (b.label || "").toLowerCase().indexOf(q) !== -1
            || (b.chord || "").toLowerCase().indexOf(q) !== -1
            || (b.action || b.sig || "").toLowerCase().indexOf(q) !== -1;
    }

    readonly property int matchCount: {
        let n = NiriKeybinds.shellActionRows.filter(b => _match(b)).length
              + NiriKeybinds.extraShellBinds.filter(b => _match(b)).length;
        for (const c of NiriKeybinds.categoryMeta)
            n += NiriKeybinds.bindsIn(c.key).filter(b => _match(b)).length;
        return n;
    }

    // --- status: errors / setup / seeding / reload --------------------
    SettingsGroup {
        caption: "Keybinds"
        icon: "󰥻"
        hint: NiriKeybinds.split ? NiriKeybinds.binds.length + " bound" : ""

        SettingsRow {
            visible: NiriKeybinds.lastError.length > 0
            icon: "󰀦"
            title: "Change reverted"
            subtitle: NiriKeybinds.lastError
        }

        SettingsRow {
            visible: NiriKeybinds.split && !NiriKeybinds.hasShellBinds
            icon: "󰐕"
            title: "Add the default shell shortcuts"
            subtitle: "Mod+Space dashboard · Mod+, settings · Mod+/ launcher · "
                + "Mod+Shift+N do-not-disturb · Mod+Shift+W next wallpaper "
                + "(skips any key that's already taken)"
            PillButton {
                text: "Add"
                accent: true
                enabledButton: !NiriKeybinds.busy
                onClicked: NiriKeybinds.seedShellDefaults()
            }
        }

        SettingsRow {
            visible: NiriKeybinds.split
            icon: "󰑓"
            title: "Reload niri"
            subtitle: "Re-read the config after editing the file by hand"
            PillButton {
                text: "Reload"
                onClicked: NiriConfig.reloadNiri()
            }
        }
    }

    // --- setup prompt --------------------------------------------------
    SettingsGroup {
        visible: !NiriKeybinds.split
        caption: "Set up"
        icon: "󰈔"

        SettingsRow {
            icon: "󰩫"
            title: "Split out the binds block"
            subtitle: "Moves binds { } from config.kdl into "
                + "~/.config/niri/quickshell/binds.kdl (verbatim) and adds an "
                + "include, so it can be edited here. A backup is kept, the "
                + "result is validated, and a few shell shortcuts are seeded."
            PillButton {
                text: NiriKeybinds.busy ? "Working…" : "Set up"
                accent: true
                enabledButton: !NiriKeybinds.busy
                onClicked: NiriKeybinds.runSplit()
            }
        }
    }

    // --- search + scrollable list -----------------------------------
    ColumnLayout {
        Layout.fillWidth: true
        visible: NiriKeybinds.split
        spacing: Theme.spacing.small

        // search field (stays put while the list below scrolls)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 44
            radius: Theme.rounding.full
            color: Theme.colors.surfaceVariant
            border.width: 1
            border.color: searchInput.activeFocus ? Theme.colors.accent : Theme.colors.borderSubtle
            Behavior on border.color { ColorAnimation { duration: Theme.animation.fast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing.medium
                anchors.rightMargin: Theme.spacing.small
                spacing: Theme.spacing.small

                Text {
                    text: "󰍉"
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.medium
                    color: Theme.colors.textTertiary
                }
                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    placeholderText: "Search shortcuts, keys or commands"
                    color: Theme.colors.textPrimary
                    placeholderTextColor: Theme.colors.textTertiary
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.medium
                    leftPadding: 0
                    rightPadding: 0
                    background: Item {}
                    onTextChanged: page.query = text
                    // Enter drops focus; Esc clears first, then drops focus.
                    onAccepted: focus = false
                    Keys.onEscapePressed: event => {
                        if (text.length > 0) text = "";
                        else focus = false;
                        event.accepted = true;
                    }
                }
                IconButton {
                    visible: searchInput.text.length > 0
                    icon: "󰅖"
                    round: true
                    size: 26
                    onClicked: searchInput.clear()
                }
            }
        }

        // the scroll pane
        Flickable {
            id: listFlick
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(300, page.height - 300)
            clip: true
            contentWidth: width
            contentHeight: listCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            // Clicking / scrolling the list dismisses the search field's focus.
            onMovementStarted: searchInput.focus = false
            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: searchInput.focus = false
            }

            ColumnLayout {
                id: listCol
                width: listFlick.width - Theme.spacing.small
                spacing: Theme.spacing.large

                // --- quickshell widgets (always listed) ---------------
                SettingsGroup {
                    id: widgetGroup
                    readonly property var rows: NiriKeybinds.shellActionRows
                        .filter(b => page._match(b))
                        .concat(NiriKeybinds.extraShellBinds.filter(b => page._match(b)))
                    visible: rows.length > 0
                    collapsible: true
                    forceExpand: page.query.length > 0
                    caption: "Shell & widgets"
                    icon: "󰐃"
                    hint: "Can't be removed — bind them to a key or leave them off"

                    Repeater {
                        model: widgetGroup.rows
                        delegate: BindRow {
                            required property var modelData
                            bind: modelData
                            widget: modelData.sig !== undefined && modelData.action === undefined
                        }
                    }
                }

                // --- one group per niri category --------------------
                Repeater {
                    model: NiriKeybinds.categoryMeta

                    delegate: SettingsGroup {
                        id: catGroup
                        required property var modelData
                        readonly property var rows: NiriKeybinds.bindsIn(modelData.key).filter(b => page._match(b))
                        visible: rows.length > 0
                        collapsible: true
                        forceExpand: page.query.length > 0
                        caption: modelData.title
                        icon: modelData.icon
                        hint: modelData.hint

                        Repeater {
                            model: catGroup.rows
                            delegate: BindRow {
                                required property var modelData
                                bind: modelData
                                removable: true
                            }
                        }
                    }
                }

                // nothing matched the search
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing.large
                    horizontalAlignment: Text.AlignHCenter
                    visible: page.query.length > 0 && page.matchCount === 0
                    text: "No shortcut matches “" + page.query + "”"
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.medium
                    color: Theme.colors.textTertiary
                }
            }
        }
    }

    // ================================================================
    // One row — a niri bind (removable) or a widget action (not).
    component BindRow: Rectangle {
        id: br
        property var bind
        property bool removable: false
        property bool widget: false
        property bool open: false

        readonly property bool isDisabled: bind.disabled === true
        readonly property bool isBound: widget ? (bind.bound === true) : true

        // segmented-run rounding, driven by SettingsGroup.relayout()
        property string blockPosition: "single"
        property bool inGroup: false
        readonly property int _outer: Theme.rounding.xhuge
        readonly property int _inner: Theme.rounding.connJoin

        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + Theme.spacing.normal * 2
        color: br.open || hov.hovered ? Theme.palette.surface2 : Theme.colors.surfaceVariant
        opacity: br.isDisabled && !br.open ? 0.55 : 1
        topLeftRadius: (blockPosition === "top" || blockPosition === "single") ? _outer : _inner
        topRightRadius: topLeftRadius
        bottomLeftRadius: (blockPosition === "bottom" || blockPosition === "single") ? _outer : _inner
        bottomRightRadius: bottomLeftRadius
        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

        HoverHandler { id: hov }

        ColumnLayout {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.spacing.large
            anchors.rightMargin: Theme.spacing.medium
            spacing: Theme.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: -1
                    Text {
                        Layout.fillWidth: true
                        text: br.bind.label
                        elide: Text.ElideRight
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.large
                        color: Theme.colors.textPrimary
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: !br.open && text.length > 0
                        text: br.widget ? br.bind.desc : br.bind.action
                        elide: Text.ElideRight
                        font.family: br.widget ? Theme.font.main : Theme.font.mono
                        font.pointSize: Theme.font.small
                        color: Theme.colors.textTertiary
                    }
                }

                // status / chord pill
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    visible: !br.open
                    implicitWidth: pill.implicitWidth + Theme.spacing.normal * 2
                    implicitHeight: 26
                    radius: Theme.rounding.small
                    color: br.isBound && !br.isDisabled ? Theme.palette.surface2 : "transparent"
                    border.width: 1
                    border.color: br.isBound && !br.isDisabled
                        ? Theme.colors.borderSubtle : Theme.colors.border
                    Text {
                        id: pill
                        anchors.centerIn: parent
                        text: !br.isBound ? "Not bound"
                            : br.isDisabled ? "Disabled" : br.bind.chord
                        font.family: br.isBound && !br.isDisabled ? Theme.font.mono : Theme.font.main
                        font.pointSize: Theme.font.small
                        font.weight: Theme.font.semiBold
                        color: br.isBound && !br.isDisabled
                            ? Theme.colors.textSecondary : Theme.colors.textTertiary
                    }
                }

                IconButton {
                    Layout.alignment: Qt.AlignVCenter
                    icon: br.open ? "󰅖" : "󰏫"
                    round: true
                    size: 30
                    onClicked: {
                        if (!br.open) {
                            chordField.text = br.bind.chord || "";
                            if (!br.widget) actionField.text = br.bind.action;
                        }
                        br.open = !br.open;
                    }
                }
            }

            // --- inline editor -------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                visible: br.open
                spacing: Theme.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.small
                    Text {
                        text: "Keys"
                        Layout.preferredWidth: 52
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.small
                        color: Theme.colors.textTertiary
                    }
                    EditField {
                        id: chordField
                        Layout.fillWidth: true
                        placeholder: "focus and press a shortcut, or type e.g. Mod+Shift+Return"
                        capture: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: !br.widget
                    spacing: Theme.spacing.small
                    Text {
                        text: "Runs"
                        Layout.preferredWidth: 52
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.small
                        color: Theme.colors.textTertiary
                    }
                    EditField {
                        id: actionField
                        Layout.fillWidth: true
                        placeholder: 'spawn "kitty"  ·  focus-column-left'
                        mono: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing.small

                    // left cluster: destructive / state
                    PillButton {
                        visible: br.removable
                        text: "Remove"
                        danger: true
                        enabledButton: !NiriKeybinds.busy
                        onClicked: { NiriKeybinds.remove(br.bind.chord); br.open = false; }
                    }
                    PillButton {
                        visible: br.removable && br.isBound
                        text: br.isDisabled ? "Enable" : "Disable"
                        enabledButton: !NiriKeybinds.busy
                        onClicked: {
                            if (br.isDisabled) NiriKeybinds.enable(br.bind.chord);
                            else NiriKeybinds.disable(br.bind.chord);
                            br.open = false;
                        }
                    }
                    PillButton {
                        visible: br.widget && br.isBound
                        text: "Set to no key"
                        danger: true
                        enabledButton: !NiriKeybinds.busy
                        onClicked: { NiriKeybinds.clearShellAction(br.bind.sig); br.open = false; }
                    }

                    Item { Layout.fillWidth: true }

                    PillButton {
                        text: "Cancel"
                        onClicked: br.open = false
                    }
                    PillButton {
                        text: NiriKeybinds.busy ? "Saving…" : "Save"
                        accent: true
                        enabledButton: !NiriKeybinds.busy
                        onClicked: {
                            const c = chordField.text.trim();
                            if (br.widget) {
                                if (c) NiriKeybinds.bindShellAction(br.bind.sig, c);
                            } else {
                                const a = actionField.text.trim();
                                if (a && a !== br.bind.action)
                                    NiriKeybinds.setAction(br.bind.chord, a);
                                if (c && c !== br.bind.chord)
                                    NiriKeybinds.rechord(br.bind.chord, c);
                            }
                            br.open = false;
                        }
                    }
                }
            }
        }
    }

    // A themed single-line text field. `capture: true` turns key presses into
    // a niri chord string instead of typing them.
    component EditField: Rectangle {
        id: ef
        property alias text: input.text
        property string placeholder: ""
        property bool mono: false
        property bool capture: false

        implicitHeight: 38
        radius: Theme.rounding.small
        color: Theme.colors.surface
        border.width: 1
        border.color: input.activeFocus ? Theme.colors.accent : Theme.colors.borderSubtle
        Behavior on border.color { ColorAnimation { duration: Theme.animation.fast } }

        function keyName(event) {
            const k = event.key;
            if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k);
            if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k);
            if (k >= Qt.Key_F1 && k <= Qt.Key_F12) return "F" + (k - Qt.Key_F1 + 1);
            const map = {};
            map[Qt.Key_Left] = "Left"; map[Qt.Key_Right] = "Right";
            map[Qt.Key_Up] = "Up"; map[Qt.Key_Down] = "Down";
            map[Qt.Key_Space] = "Space"; map[Qt.Key_Return] = "Return";
            map[Qt.Key_Enter] = "Return"; map[Qt.Key_Tab] = "Tab";
            map[Qt.Key_Home] = "Home"; map[Qt.Key_End] = "End";
            map[Qt.Key_PageUp] = "Page_Up"; map[Qt.Key_PageDown] = "Page_Down";
            map[Qt.Key_Slash] = "Slash"; map[Qt.Key_Backslash] = "Backslash";
            map[Qt.Key_Comma] = "Comma"; map[Qt.Key_Period] = "Period";
            map[Qt.Key_Minus] = "Minus"; map[Qt.Key_Equal] = "Equal";
            map[Qt.Key_Semicolon] = "Semicolon"; map[Qt.Key_Apostrophe] = "Apostrophe";
            map[Qt.Key_BracketLeft] = "BracketLeft"; map[Qt.Key_BracketRight] = "BracketRight";
            map[Qt.Key_Print] = "Print"; map[Qt.Key_Delete] = "Delete";
            return map[k] ?? "";
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing.normal
            anchors.rightMargin: Theme.spacing.normal
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            color: Theme.colors.textPrimary
            selectByMouse: true
            selectionColor: Theme.colors.accent
            font.family: ef.mono ? Theme.font.mono : Theme.font.main
            font.pointSize: Theme.font.medium

            Keys.onPressed: event => {
                if (!ef.capture) return;
                if (event.key === Qt.Key_Shift || event.key === Qt.Key_Control
                    || event.key === Qt.Key_Alt || event.key === Qt.Key_Meta
                    || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) {
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Escape || event.key === Qt.Key_Backspace) return;
                const name = ef.keyName(event);
                if (!name) { event.accepted = true; return; }
                const mods = [];
                if (event.modifiers & Qt.MetaModifier) mods.push("Mod");
                if (event.modifiers & Qt.ControlModifier) mods.push("Ctrl");
                if (event.modifiers & Qt.AltModifier) mods.push("Alt");
                if (event.modifiers & Qt.ShiftModifier) mods.push("Shift");
                input.text = mods.concat([name]).join("+");
                event.accepted = true;
            }

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: input.text.length === 0
                text: ef.placeholder
                elide: Text.ElideRight
                font.family: input.font.family
                font.pointSize: input.font.pointSize
                color: Theme.colors.textTertiary
            }
        }
    }
}
