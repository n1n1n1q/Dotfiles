import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.modules.settings

// Google Tasks to-do list inside CalendarCard: a checkable list with a
// quick-add field, per-task inline edit (title / due / delete), an optional
// list switcher and a "show completed" toggle. Collapsible.
ColumnLayout {
    id: root

    property bool expanded: true
    property string listKeyOverride: ""
    readonly property string listKey: listKeyOverride || GoogleCalendar.effectiveTaskListKey
    readonly property var _tasks: GoogleCalendar.tasksFor(listKey)

    // Keys the user just deleted — collapse the row now rather than waiting for
    // the sync round-trip. A fresh task list (new sync) is the source of truth
    // and clears these.
    property var _hiddenKeys: []
    on_TasksChanged: _hiddenKeys = []
    function _hide(key) {
        const h = _hiddenKeys.slice();
        if (h.indexOf(key) < 0) h.push(key);
        _hiddenKeys = h;
    }
    readonly property int _open: GoogleCalendar.tasksFor(listKey).filter(
        t => (GoogleCalendar.pendingStatus(t.key) ?? t.status) !== "completed").length

    property string editKey: ""

    readonly property int fHead: Theme.bar.fontSize - 1
    readonly property int fRow: Theme.bar.fontSize
    readonly property int fMeta: Theme.bar.fontSize - 2

    spacing: Theme.spacing.tiny

    component EditChip: Rectangle {
        property string glyph: ""
        property bool danger: false
        signal tap()
        implicitWidth: 26
        implicitHeight: 26
        radius: Theme.rounding.small
        color: chipMouse.containsMouse
            ? (danger ? Qt.rgba(Theme.colors.error.r, Theme.colors.error.g, Theme.colors.error.b, 0.18)
                      : Theme.colors.surfaceVariant)
            : "transparent"
        Text {
            anchors.centerIn: parent
            text: parent.glyph
            font.family: Theme.font.icon
            font.pointSize: root.fMeta
            color: parent.danger ? Theme.colors.error : Theme.colors.textSecondary
        }
        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.tap()
        }
    }

    function _pad(n) { return (n < 10 ? "0" : "") + n; }
    function _ymd(d) { return d.getFullYear() + "-" + _pad(d.getMonth() + 1) + "-" + _pad(d.getDate()); }
    function _dueDate(t) {
        if (!t.due) return null;
        const p = t.due.slice(0, 10).split("-");
        return new Date(+p[0], +p[1] - 1, +p[2]);
    }
    function _dueLabel(t) {
        const d = _dueDate(t);
        if (!d) return "";
        const today = new Date(); today.setHours(0, 0, 0, 0);
        const diff = Math.round((d - today) / 86400000);
        if (diff === 0) return "Today";
        if (diff === 1) return "Tomorrow";
        if (diff === -1) return "Yesterday";
        return Qt.formatDate(d, "d MMM");
    }

    // --- header -----------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.tiny
        spacing: Theme.spacing.small

        Text {
            text: "󰄴"
            font.family: Theme.font.icon
            font.pointSize: root.fHead
            color: Theme.colors.textSecondary
        }
        Text {
            text: "Tasks"
            font.family: Theme.font.main
            font.pointSize: root.fHead
            font.weight: Theme.font.semiBold
            color: Theme.colors.textPrimary
        }
        Text {
            visible: root._open > 0
            text: root._open
            font.family: Theme.font.main
            font.pointSize: root.fMeta
            color: Theme.colors.textTertiary
        }

        Item { Layout.fillWidth: true }

        // list switcher
        ComboBox {
            id: listCombo
            visible: GoogleCalendar.taskLists.length > 1
            Layout.preferredWidth: 132
            font.family: Theme.font.main
            font.pointSize: root.fMeta
            model: GoogleCalendar.taskLists.map(l => l.title)
            currentIndex: Math.max(0, GoogleCalendar.taskLists.findIndex(l => l.key === root.listKey))
            onActivated: root.listKeyOverride = GoogleCalendar.taskLists[currentIndex].key
        }

        Text {
            visible: GoogleCalendar.connected
            text: root.expanded ? "󰅃" : "󰅀"
            font.family: Theme.font.icon
            font.pointSize: root.fMeta
            color: Theme.colors.textTertiary
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expanded = !root.expanded
            }
        }
    }

    // --- not connected --------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        visible: !GoogleCalendar.connected
        implicitHeight: 34
        radius: Theme.rounding.small
        color: ncMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacing.small
            anchors.rightMargin: Theme.spacing.small
            Text {
                Layout.fillWidth: true
                text: "Connect a Google account"
                font.family: Theme.font.main
                font.pointSize: root.fMeta
                color: Theme.colors.textSecondary
            }
            Text {
                text: "󰅂"
                font.family: Theme.font.icon
                font.pointSize: root.fMeta
                color: Theme.colors.textTertiary
            }
        }
        MouseArea {
            id: ncMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: SettingsController.show("calendar")
        }
    }

    // --- body ---------------------------------------------------
    ColumnLayout {
        Layout.fillWidth: true
        visible: GoogleCalendar.connected && root.expanded
        spacing: Theme.spacing.tiny

        // quick-add
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 30
            radius: Theme.rounding.small
            color: Theme.colors.surface
            border.width: 1
            border.color: addField.activeFocus ? Theme.colors.accent : Theme.colors.borderSubtle
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing.small
                anchors.rightMargin: Theme.spacing.small
                spacing: Theme.spacing.tiny
                Text {
                    text: "󰐕"
                    font.family: Theme.font.icon
                    font.pointSize: root.fMeta
                    color: Theme.colors.textTertiary
                }
                TextField {
                    id: addField
                    Layout.fillWidth: true
                    placeholderText: "Add a task…"
                    color: Theme.colors.textPrimary
                    placeholderTextColor: Theme.colors.textTertiary
                    font.family: Theme.font.main
                    font.pointSize: root.fRow
                    background: Item {}
                    onAccepted: {
                        if (text.trim().length) {
                            GoogleCalendar.addTask(root.listKey, text.trim(), "");
                            text = "";
                        }
                    }
                }
            }
        }

        Repeater {
            model: root._tasks
            delegate: Item {
                id: taskItem
                required property var modelData
                Layout.fillWidth: true
                readonly property string st:
                    GoogleCalendar.pendingStatus(modelData.key) ?? modelData.status
                readonly property bool done: st === "completed"
                readonly property bool open: root.editKey === modelData.key
                readonly property bool gone: root._hiddenKeys.indexOf(modelData.key) >= 0

                clip: true
                implicitHeight: gone ? 0 : taskCol.implicitHeight
                opacity: gone ? 0 : appear
                Behavior on implicitHeight {
                    NumberAnimation { duration: Theme.animation.normal; easing.type: Easing.OutCubic }
                }
                Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }

                // slide + fade in on mount
                property real appear: 0
                property real slide: 12
                Component.onCompleted: { appear = 1; slide = 0; }
                Behavior on slide {
                    NumberAnimation { duration: Theme.animation.normal; easing.type: Easing.OutCubic }
                }

                ColumnLayout {
                    id: taskCol
                    width: parent.width
                    x: taskItem.slide
                    spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: Theme.rounding.small
                    color: tMouse.containsMouse
                        ? Qt.rgba(Theme.colors.textPrimary.r, Theme.colors.textPrimary.g,
                                  Theme.colors.textPrimary.b, 0.06)
                        : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                    MouseArea {
                        id: tMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.editKey = taskItem.open ? "" : taskItem.modelData.key
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacing.tiny
                        anchors.rightMargin: Theme.spacing.small
                        spacing: Theme.spacing.small

                        Rectangle {
                            implicitWidth: 18; implicitHeight: 18
                            radius: 9
                            color: taskItem.done ? Theme.colors.accent : "transparent"
                            border.width: 1.5
                            border.color: taskItem.done ? Theme.colors.accent : Theme.colors.textTertiary
                            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
                            Behavior on border.color { ColorAnimation { duration: Theme.animation.fast } }
                            Text {
                                anchors.centerIn: parent
                                visible: taskItem.done
                                text: "󰄬"
                                font.family: Theme.font.icon
                                font.pointSize: root.fMeta
                                color: Theme.colors.bg
                                scale: taskItem.done ? 1 : 0
                                Behavior on scale {
                                    NumberAnimation { duration: Theme.animation.fast; easing.type: Easing.OutBack }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: GoogleCalendar.toggleTask(taskItem.modelData)
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: taskItem.modelData.title || "(untitled)"
                            elide: Text.ElideRight
                            font.family: Theme.font.main
                            font.pointSize: root.fRow
                            font.strikeout: taskItem.done
                            color: taskItem.done ? Theme.colors.textTertiary : Theme.colors.textPrimary
                            Behavior on color { ColorAnimation { duration: Theme.animation.normal } }
                        }

                        Text {
                            visible: root._dueLabel(taskItem.modelData).length > 0
                            text: root._dueLabel(taskItem.modelData)
                            font.family: Theme.font.main
                            font.pointSize: root.fMeta
                            color: {
                                const d = root._dueDate(taskItem.modelData);
                                const t = new Date(); t.setHours(0, 0, 0, 0);
                                return (d && d < t && !taskItem.done)
                                    ? Theme.colors.error : Theme.colors.textTertiary;
                            }
                        }
                    }
                }

                // inline editor — slides open / shut
                Item {
                    Layout.fillWidth: true
                    clip: true
                    implicitHeight: teLoader.active ? teLoader.implicitHeight : 0
                    opacity: teLoader.active ? 1 : 0
                    Behavior on implicitHeight {
                        NumberAnimation { duration: Theme.animation.normal; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }

                Loader {
                    id: teLoader
                    width: parent.width
                    active: taskItem.open
                    sourceComponent: Rectangle {
                        implicitHeight: te.implicitHeight + Theme.spacing.small * 2
                        radius: Theme.rounding.small
                        color: Qt.rgba(Theme.colors.textPrimary.r, Theme.colors.textPrimary.g,
                                       Theme.colors.textPrimary.b, 0.04)

                        RowLayout {
                            id: te
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Theme.spacing.small
                            spacing: Theme.spacing.tiny

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: Theme.rounding.small
                                color: Theme.colors.surface
                                border.width: 1
                                border.color: Theme.colors.borderSubtle
                                TextField {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacing.small
                                    text: taskItem.modelData.title
                                    color: Theme.colors.textPrimary
                                    font.family: Theme.font.main
                                    font.pointSize: root.fRow
                                    background: Item {}
                                    onAccepted: {
                                        GoogleCalendar.editTask(taskItem.modelData, { title: text.trim() });
                                        root.editKey = "";
                                    }
                                }
                            }

                            EditChip {
                                glyph: "󰅁"
                                onTap: {
                                    const d = root._dueDate(taskItem.modelData) || new Date();
                                    GoogleCalendar.editTask(taskItem.modelData,
                                        { due: root._ymd(new Date(d.getTime() - 86400000)) });
                                }
                            }
                            Text {
                                text: root._dueLabel(taskItem.modelData) || "no date"
                                Layout.minimumWidth: 52
                                horizontalAlignment: Text.AlignHCenter
                                font.family: Theme.font.main
                                font.pointSize: root.fMeta
                                color: Theme.colors.textSecondary
                            }
                            EditChip {
                                glyph: "󰅂"
                                onTap: {
                                    const d = root._dueDate(taskItem.modelData) || new Date();
                                    GoogleCalendar.editTask(taskItem.modelData,
                                        { due: root._ymd(new Date(d.getTime() + 86400000)) });
                                }
                            }
                            EditChip {
                                glyph: "󰅖"
                                visible: !!taskItem.modelData.due
                                onTap: GoogleCalendar.editTask(taskItem.modelData, { clearDue: true })
                            }
                            EditChip {
                                glyph: "󰩹"
                                danger: true
                                onTap: {
                                    root.editKey = "";
                                    root._hide(taskItem.modelData.key);
                                    GoogleCalendar.deleteTask(taskItem.modelData);
                                }
                            }
                        }
                    }
                }
                }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root._tasks.length === 0
            text: "All clear"
            horizontalAlignment: Text.AlignHCenter
            font.family: Theme.font.main
            font.pointSize: root.fMeta
            color: Theme.colors.textTertiary
        }

        // show-completed toggle
        Text {
            Layout.topMargin: Theme.spacing.tiny
            text: (GoogleConfig.showCompletedTasks ? "󰄲  Hide completed" : "󰄱  Show completed")
            font.family: Theme.font.main
            font.pointSize: root.fMeta
            color: Theme.colors.textTertiary
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: GoogleConfig.setShowCompleted(!GoogleConfig.showCompletedTasks)
            }
        }
    }
}
