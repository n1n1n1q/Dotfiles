import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services

// The selected day's event list inside CalendarCard. A tap on a row opens
// CalEventEditor in place; the header "+" opens it in create mode.
ColumnLayout {
    id: root

    property date day: new Date()

    readonly property var _events: GoogleCalendar.eventsOn(day)
    readonly property var _writable: GoogleCalendar.writableCalendars

    property var editorEvent: null
    property bool editorOpen: false

    readonly property int fHead: Theme.bar.fontSize - 1
    readonly property int fRow: Theme.bar.fontSize
    readonly property int fMeta: Theme.bar.fontSize - 2

    spacing: Theme.spacing.tiny

    onDayChanged: { editorOpen = false; editorEvent = null; }

    function _timeLabel(e) {
        if (e.allDay) return "All day";
        const s = GoogleCalendar._parseDay(e.start, false);
        const en = GoogleCalendar._parseDay(e.end, false);
        const f = d => Qt.formatTime(d, "HH:mm");
        return en && en > s ? f(s) + " – " + f(en) : f(s);
    }

    // --- header -------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.small

        Text {
            Layout.fillWidth: true
            text: Qt.formatDate(root.day, "dddd d MMMM")
            font.family: Theme.font.main
            font.pointSize: root.fHead
            font.weight: Theme.font.semiBold
            color: Theme.colors.textPrimary
        }

        Rectangle {
            visible: root._writable.length > 0 && !root.editorOpen
            implicitWidth: 24; implicitHeight: 24
            radius: Theme.rounding.small
            color: addMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent"
            Text {
                anchors.centerIn: parent
                text: "󰐕"
                font.family: Theme.font.icon
                font.pointSize: root.fHead
                color: Theme.colors.textSecondary
            }
            MouseArea {
                id: addMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.editorEvent = null; root.editorOpen = true; }
            }
        }
    }

    // --- editor -----------------------------------------------------
    Loader {
        Layout.fillWidth: true
        active: root.editorOpen
        visible: active
        sourceComponent: CalEventEditor {
            event: root.editorEvent
            defaultDay: root.day
            calendars: root._writable
            onClosed: { root.editorOpen = false; root.editorEvent = null; }
        }
    }

    // --- list ------------------------------------------------------
    ListView {
        id: list
        Layout.fillWidth: true
        visible: !root.editorOpen && root._events.length > 0
        implicitHeight: Math.min(contentHeight, 172)
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        spacing: 2
        model: root._events

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            id: row
            required property var modelData
            width: list.width
            implicitHeight: Math.max(40, rowCol.implicitHeight + Theme.spacing.small)
            radius: Theme.rounding.small
            color: rMouse.containsMouse
                ? Qt.rgba(Theme.colors.textPrimary.r, Theme.colors.textPrimary.g,
                          Theme.colors.textPrimary.b, 0.06)
                : "transparent"

            Rectangle {
                id: bar
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: parent.height - Theme.spacing.small
                radius: 1.5
                color: row.modelData.bg || Theme.colors.accent
            }

            ColumnLayout {
                id: rowCol
                anchors.left: bar.right
                anchors.leftMargin: Theme.spacing.small
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing.small
                anchors.verticalCenter: parent.verticalCenter
                spacing: -1

                Text {
                    Layout.fillWidth: true
                    text: root._timeLabel(row.modelData)
                    font.family: Theme.font.main
                    font.pointSize: root.fMeta
                    color: Theme.colors.textTertiary
                }
                Text {
                    Layout.fillWidth: true
                    text: row.modelData.title
                    elide: Text.ElideRight
                    font.family: Theme.font.main
                    font.pointSize: root.fRow
                    color: Theme.colors.textPrimary
                }
                Text {
                    Layout.fillWidth: true
                    visible: (row.modelData.location || "").length > 0
                    text: "󰍎  " + row.modelData.location
                    elide: Text.ElideRight
                    font.family: Theme.font.main
                    font.pointSize: root.fMeta
                    color: Theme.colors.textTertiary
                }
            }

            MouseArea {
                id: rMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: row.modelData.editable ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (!row.modelData.editable) return;
                    root.editorEvent = row.modelData;
                    root.editorOpen = true;
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacing.tiny
        visible: !root.editorOpen && root._events.length === 0
        text: GoogleCalendar.connected ? "Nothing scheduled" : ""
        horizontalAlignment: Text.AlignHCenter
        font.family: Theme.font.main
        font.pointSize: root.fMeta
        color: Theme.colors.textTertiary
    }
}
