import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services

// Inline create / edit / delete panel for a single calendar event, shown
// expanded inside CalAgenda. Times are edited with tap steppers (no keyboard
// date picker) so it stays usable in a dropdown.
Rectangle {
    id: root

    property var event: null                 // null → create mode
    property date defaultDay: new Date()
    property var calendars: []               // writable calendars

    signal closed()

    readonly property bool editing: event !== null
    readonly property int fLabel: Theme.bar.fontSize - 2
    readonly property int fVal: Theme.bar.fontSize

    color: Qt.rgba(Theme.colors.textPrimary.r, Theme.colors.textPrimary.g,
                   Theme.colors.textPrimary.b, 0.04)
    radius: Theme.rounding.small
    implicitHeight: form.implicitHeight + Theme.spacing.normal * 2

    // --- working state ------------------------------------------------
    property string wTitle: ""
    property string wLocation: ""
    property bool wAllDay: false
    property date wStart: new Date()
    property date wEnd: new Date()
    property string wCalKey: ""

    function _pad(n) { return (n < 10 ? "0" : "") + n; }
    function _ymd(d) { return d.getFullYear() + "-" + _pad(d.getMonth() + 1) + "-" + _pad(d.getDate()); }
    function _localStamp(d) {
        return _ymd(d) + "T" + _pad(d.getHours()) + ":" + _pad(d.getMinutes());
    }
    function _withDate(base, y, m, day) {
        return new Date(y, m, day, base.getHours(), base.getMinutes());
    }
    function _withTime(base, h, mn) {
        return new Date(base.getFullYear(), base.getMonth(), base.getDate(), h, mn);
    }

    Component.onCompleted: {
        if (editing) {
            wTitle = event.title === "(no title)" ? "" : event.title;
            wLocation = event.location || "";
            wAllDay = event.allDay;
            wStart = GoogleCalendar._parseDay(event.start, event.allDay) || new Date();
            let en = GoogleCalendar._parseDay(event.end, event.allDay);
            if (event.allDay && en) en = new Date(en.getTime() - 86400000); // inclusive
            wEnd = en || new Date(wStart.getTime() + 3600000);
            wCalKey = event.calendarKey;
        } else {
            const d = defaultDay;
            const now = new Date();
            wStart = new Date(d.getFullYear(), d.getMonth(), d.getDate(), now.getHours() + 1, 0);
            wEnd = new Date(wStart.getTime() + 3600000);
            wCalKey = calendars.length ? calendars[0].key : "";
        }
    }

    component FieldBox: Rectangle {
        default property alias data: inner.data
        Layout.fillWidth: true
        implicitHeight: 30
        radius: Theme.rounding.small
        color: Theme.colors.surface
        border.width: 1
        border.color: Theme.colors.borderSubtle
        RowLayout { id: inner; anchors.fill: parent; anchors.leftMargin: Theme.spacing.small; anchors.rightMargin: Theme.spacing.tiny }
    }

    component ChevBtn: Rectangle {
        property string g: ""
        signal tapped()
        implicitWidth: 22; implicitHeight: 22
        radius: Theme.rounding.small
        color: chMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent"
        Text { anchors.centerIn: parent; text: parent.g; font.family: Theme.font.icon
               font.pointSize: root.fLabel; color: Theme.colors.textSecondary }
        MouseArea { id: chMouse; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor; onClicked: parent.tapped() }
    }

    component Stepper: RowLayout {
        property string text: ""
        signal minus()
        signal plus()
        spacing: 0
        ChevBtn { g: "󰅁"; onTapped: parent.minus() }
        Text {
            Layout.minimumWidth: 84
            horizontalAlignment: Text.AlignHCenter
            text: parent.text
            font.family: Theme.font.main
            font.pointSize: root.fVal
            color: Theme.colors.textPrimary
        }
        ChevBtn { g: "󰅂"; onTapped: parent.plus() }
    }

    ColumnLayout {
        id: form
        anchors.fill: parent
        anchors.margins: Theme.spacing.normal
        spacing: Theme.spacing.small

        FieldBox {
            TextField {
                id: titleField
                Layout.fillWidth: true
                text: root.wTitle
                placeholderText: "Title"
                color: Theme.colors.textPrimary
                placeholderTextColor: Theme.colors.textTertiary
                font.family: Theme.font.main
                font.pointSize: root.fVal
                background: Item {}
                onTextChanged: root.wTitle = text
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small
            Text {
                text: "All day"
                font.family: Theme.font.main
                font.pointSize: root.fVal
                color: Theme.colors.textSecondary
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                implicitWidth: 40; implicitHeight: 22
                radius: height / 2
                color: root.wAllDay ? Theme.colors.accent : Theme.colors.surface
                border.width: 1
                border.color: root.wAllDay ? Theme.colors.accent : Theme.colors.borderSubtle
                Rectangle {
                    width: 16; height: 16; radius: 8
                    y: 3
                    x: root.wAllDay ? parent.width - width - 3 : 3
                    color: root.wAllDay ? Theme.colors.bg : Theme.colors.textTertiary
                    Behavior on x { NumberAnimation { duration: Theme.animation.fast } }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.wAllDay = !root.wAllDay }
            }
        }

        // start
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Start"; Layout.minimumWidth: 40; font.family: Theme.font.main
                   font.pointSize: root.fLabel; color: Theme.colors.textTertiary }
            Item { Layout.fillWidth: true }
            Stepper {
                text: Qt.formatDate(root.wStart, "ddd d MMM")
                onMinus: root.wStart = new Date(root.wStart.getTime() - 86400000)
                onPlus:  root.wStart = new Date(root.wStart.getTime() + 86400000)
            }
            Stepper {
                visible: !root.wAllDay
                text: root._pad(root.wStart.getHours()) + ":" + root._pad(root.wStart.getMinutes())
                onMinus: root.wStart = new Date(root.wStart.getTime() - 900000)
                onPlus:  root.wStart = new Date(root.wStart.getTime() + 900000)
            }
        }

        // end
        RowLayout {
            Layout.fillWidth: true
            Text { text: "End"; Layout.minimumWidth: 40; font.family: Theme.font.main
                   font.pointSize: root.fLabel; color: Theme.colors.textTertiary }
            Item { Layout.fillWidth: true }
            Stepper {
                text: Qt.formatDate(root.wEnd, "ddd d MMM")
                onMinus: root.wEnd = new Date(root.wEnd.getTime() - 86400000)
                onPlus:  root.wEnd = new Date(root.wEnd.getTime() + 86400000)
            }
            Stepper {
                visible: !root.wAllDay
                text: root._pad(root.wEnd.getHours()) + ":" + root._pad(root.wEnd.getMinutes())
                onMinus: root.wEnd = new Date(root.wEnd.getTime() - 900000)
                onPlus:  root.wEnd = new Date(root.wEnd.getTime() + 900000)
            }
        }

        FieldBox {
            TextField {
                Layout.fillWidth: true
                text: root.wLocation
                placeholderText: "Location (optional)"
                color: Theme.colors.textPrimary
                placeholderTextColor: Theme.colors.textTertiary
                font.family: Theme.font.main
                font.pointSize: root.fVal
                background: Item {}
                onTextChanged: root.wLocation = text
            }
        }

        // calendar picker
        RowLayout {
            Layout.fillWidth: true
            visible: root.calendars.length > 1 && !root.editing
            spacing: Theme.spacing.small
            Text { text: "Calendar"; font.family: Theme.font.main; font.pointSize: root.fLabel
                   color: Theme.colors.textTertiary }
            Item { Layout.fillWidth: true }
            ComboBox {
                id: calCombo
                Layout.preferredWidth: 180
                font.family: Theme.font.main
                font.pointSize: root.fLabel
                model: root.calendars.map(c => c.summary)
                currentIndex: Math.max(0, root.calendars.findIndex(c => c.key === root.wCalKey))
                onActivated: root.wCalKey = root.calendars[currentIndex].key
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.tiny
            spacing: Theme.spacing.small

            Rectangle {
                visible: root.editing
                implicitWidth: delTxt.implicitWidth + Theme.spacing.normal
                implicitHeight: 28
                radius: Theme.rounding.small
                color: delMouse.containsMouse
                    ? Qt.rgba(Theme.colors.error.r, Theme.colors.error.g, Theme.colors.error.b, 0.18)
                    : "transparent"
                Text {
                    id: delTxt
                    anchors.centerIn: parent
                    text: "Delete"
                    font.family: Theme.font.main
                    font.pointSize: root.fLabel
                    color: Theme.colors.error
                }
                MouseArea {
                    id: delMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { GoogleCalendar.deleteEvent(root.event); root.closed(); }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                implicitWidth: 64; implicitHeight: 28
                radius: Theme.rounding.small
                color: "transparent"
                Text { anchors.centerIn: parent; text: "Cancel"; font.family: Theme.font.main
                       font.pointSize: root.fLabel; color: Theme.colors.textSecondary }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.closed() }
            }
            Rectangle {
                implicitWidth: 64; implicitHeight: 28
                radius: Theme.rounding.small
                color: Theme.colors.accent
                opacity: root.wTitle.trim().length ? 1 : 0.4
                Text { anchors.centerIn: parent; text: "Save"; font.family: Theme.font.main
                       font.pointSize: root.fLabel; font.weight: Theme.font.semiBold
                       color: Theme.colors.bg }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.wTitle.trim().length > 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._save()
                }
            }
        }
    }

    function _save() {
        const patch = {
            title: wTitle.trim(),
            location: wLocation,
            allDay: wAllDay
        };
        if (wAllDay) {
            patch.allDayDate = _ymd(wStart);
            patch.allDayEnd = _ymd(new Date(wEnd.getTime() + 86400000)); // API end exclusive
        } else {
            patch.start = _localStamp(wStart);
            patch.end = _localStamp(wEnd);
        }
        if (editing) GoogleCalendar.editEvent(event, patch);
        else GoogleCalendar.addEvent(wCalKey, patch);
        closed();
    }
}
