import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services

// Anchored dropdown calendar for the bar clock. A month grid (QtQuick.Controls
// MonthGrid / DayOfWeekRow) with clickable days and a tap-to-open month/year
// picker; below it the selected day's agenda and a Google Tasks to-do list.
// Event dots + agenda + tasks come from services/GoogleCalendar once an
// account is connected in Settings › Calendar — with none, it's just the grid.
Rectangle {
    id: root

    // The month currently shown (always the 1st of that month).
    property date shownMonth: {
        const n = new Date();
        return new Date(n.getFullYear(), n.getMonth(), 1);
    }
    property date selectedDate: new Date()
    readonly property date today: new Date()

    property string view: "month"          // "month" | "picker"

    readonly property var monthEvents:
        GoogleCalendar.eventDaysInMonth(shownMonth.getFullYear(), shownMonth.getMonth())

    function step(delta) {
        shownMonth = new Date(shownMonth.getFullYear(), shownMonth.getMonth() + delta, 1);
    }
    function jumpToday() {
        const n = new Date();
        shownMonth = new Date(n.getFullYear(), n.getMonth(), 1);
        selectedDate = n;
        view = "month";
    }
    function _sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }

    // Text tracks the bar's own size so the dropdown reads as part of it.
    readonly property int fTitle: Theme.bar.fontSize        // 13
    readonly property int fDay: Theme.bar.fontSize - 2      // 11
    readonly property int fDate: Theme.bar.fontSize - 1     // 12

    implicitWidth: 380
    implicitHeight: col.implicitHeight + Theme.popup.padding * 2
    radius: Theme.popup.radius
    color: Theme.popup.background
    border.width: Theme.popup.borderWidth
    border.color: Theme.popup.border

    WheelHandler {
        acceptedModifiers: Qt.NoModifier
        enabled: root.view === "month"
        onWheel: event => root.step(event.angleDelta.y > 0 ? -1 : 1)
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: Theme.popup.padding
        spacing: Theme.spacing.small

        // --- header -----------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.tiny

            component NavBtn: Rectangle {
                id: nb
                property string glyph: ""
                signal triggered()
                implicitWidth: 26
                implicitHeight: 26
                radius: Theme.rounding.small
                color: nbMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
                Text {
                    anchors.centerIn: parent
                    text: nb.glyph
                    font.family: Theme.font.icon
                    font.pointSize: root.fTitle
                    color: Theme.colors.textSecondary
                }
                MouseArea {
                    id: nbMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: nb.triggered()
                }
            }

            NavBtn {
                glyph: "󰅁"
                visible: root.view === "month"
                onTriggered: root.step(-1)
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 26
                radius: Theme.rounding.small
                color: titleMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
                Text {
                    anchors.centerIn: parent
                    text: root.view === "picker"
                        ? "Pick a month"
                        : root.shownMonth.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    font.family: Theme.font.main
                    font.pointSize: root.fTitle
                    font.weight: Theme.font.semiBold
                    color: Theme.colors.textPrimary
                }
                MouseArea {
                    id: titleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.view = root.view === "picker" ? "month" : "picker"
                }
            }

            NavBtn {
                glyph: "󰅂"
                visible: root.view === "month"
                onTriggered: root.step(1)
            }

            NavBtn {
                glyph: "󰃰"
                onTriggered: root.jumpToday()
            }
        }

        // --- month / year picker -------------------------------------
        CalMonthPicker {
            Layout.fillWidth: true
            visible: root.view === "picker"
            year: root.shownMonth.getFullYear()
            month: root.shownMonth.getMonth()
            onPicked: (y, m) => {
                root.shownMonth = new Date(y, m, 1);
                root.view = "month";
            }
        }

        // --- month grid --------------------------------------------
        DayOfWeekRow {
            Layout.fillWidth: true
            visible: root.view === "month"
            locale: grid.locale
            delegate: Text {
                required property var model
                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font.family: Theme.font.main
                font.pointSize: root.fDay
                font.weight: Theme.font.mediumWeight
                color: (model.day === 0 || model.day === 6)
                    ? Theme.colors.textTertiary : Theme.colors.textSecondary
            }
        }

        MonthGrid {
            id: grid
            Layout.fillWidth: true
            visible: root.view === "month"
            month: root.shownMonth.getMonth()
            year: root.shownMonth.getFullYear()
            locale: Qt.locale()
            spacing: 2

            delegate: Item {
                id: cell
                required property var model
                readonly property bool isToday: root._sameDay(model.date, root.today)
                readonly property bool isSelected: root._sameDay(model.date, root.selectedDate)
                readonly property bool inMonth: model.month === grid.month
                readonly property int evCount: (inMonth && root.monthEvents[model.day]) || 0

                implicitWidth: 40
                implicitHeight: 40

                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: height / 2
                    visible: cell.isToday
                    color: Theme.colors.accent
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: height / 2
                    visible: cell.isSelected && !cell.isToday
                    color: "transparent"
                    border.width: 1.5
                    border.color: Theme.colors.accent
                }
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -2
                    text: grid.locale.toString(cell.model.day)
                    font.family: Theme.font.main
                    font.pointSize: root.fDate
                    font.weight: cell.isToday ? Theme.font.semiBold : Theme.font.regular
                    opacity: cell.inMonth ? 1 : 0.35
                    color: cell.isToday
                        ? Theme.colors.bg
                        : ((cell.model.date.getDay() === 0 || cell.model.date.getDay() === 6)
                            ? Theme.colors.textTertiary : Theme.colors.textPrimary)
                }

                // event dots
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 5
                    spacing: 2
                    visible: cell.evCount > 0
                    Repeater {
                        model: Math.min(3, cell.evCount)
                        delegate: Rectangle {
                            width: 4; height: 4; radius: 2
                            color: cell.isToday ? Theme.colors.bg : Theme.colors.accent
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedDate = cell.model.date;
                        if (!cell.inMonth)
                            root.shownMonth = new Date(cell.model.date.getFullYear(),
                                                       cell.model.date.getMonth(), 1);
                    }
                }
            }
        }

        // --- selected-day agenda -----------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.tiny
            visible: root.view === "month" && GoogleCalendar.connected
            implicitHeight: 1
            color: Theme.colors.borderSubtle
            opacity: 0.5
        }

        CalAgenda {
            Layout.fillWidth: true
            visible: root.view === "month" && GoogleCalendar.connected
            day: root.selectedDate
        }

        // --- tasks ------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Theme.colors.borderSubtle
            opacity: 0.5
        }

        CalTasks {
            Layout.fillWidth: true
        }
    }
}
