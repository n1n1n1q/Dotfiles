import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services

// Anchored dropdown calendar for the bar clock. Two whole tabs: Calendar (the
// month grid with the selected day's agenda beside it) and To-do (the Google
// Tasks list). The panes slide sideways and the host is a fixed height so the
// card never jumps. Event dots + agenda + tasks come from
// services/GoogleCalendar once an account is connected in Settings › Calendar.
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
    property int tab: 0                     // 0 = Calendar · 1 = To-do

    readonly property var monthEvents:
        GoogleCalendar.eventDaysInMonth(shownMonth.getFullYear(), shownMonth.getMonth())

    readonly property bool working: GoogleCalendar.busy || GoogleCalendar.syncing

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

    implicitWidth: 640
    implicitHeight: col.implicitHeight + Theme.popup.padding * 2
    radius: Theme.popup.radius
    color: Theme.popup.background
    border.width: Theme.popup.borderWidth
    border.color: Theme.popup.border

    WheelHandler {
        acceptedModifiers: Qt.NoModifier
        enabled: root.tab === 0 && root.view === "month"
        onWheel: event => root.step(event.angleDelta.y > 0 ? -1 : 1)
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: Theme.popup.padding
        spacing: Theme.spacing.small

        // --- sliding panes -----------------------------------------
        Item {
            id: stack
            Layout.fillWidth: true
            implicitHeight: 320
            clip: true

            Row {
                width: stack.width * 2
                height: stack.height
                x: -root.tab * stack.width
                Behavior on x {
                    NumberAnimation { duration: Theme.animation.normal; easing.type: Easing.OutCubic }
                }

                // ============ PANE 1 — Calendar ============
                ColumnLayout {
                    width: stack.width
                    height: stack.height
                    spacing: Theme.spacing.small

                    // month nav
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacing.tiny

                        // sync spinner — collapses out of the row when idle
                        Text {
                            Layout.preferredWidth: root.working ? implicitWidth : 0
                            clip: true
                            text: "󰑐"
                            visible: root.working
                            font.family: Theme.font.icon
                            font.pointSize: root.fDay
                            color: Theme.colors.accent
                            RotationAnimation on rotation {
                                running: root.working
                                loops: Animation.Infinite
                                from: 0; to: 360
                                duration: 900
                            }
                        }

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

                    // month / year picker
                    CalMonthPicker {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.view === "picker"
                        year: root.shownMonth.getFullYear()
                        month: root.shownMonth.getMonth()
                        onPicked: (y, m) => {
                            root.shownMonth = new Date(y, m, 1);
                            root.view = "month";
                        }
                    }

                    // grid (left) + agenda (right)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.view === "month"
                        spacing: Theme.spacing.medium

                        ColumnLayout {
                            Layout.preferredWidth: 296
                            Layout.maximumWidth: 296
                            Layout.fillWidth: false
                            Layout.alignment: Qt.AlignTop
                            spacing: 2

                            DayOfWeekRow {
                                Layout.fillWidth: true
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
                                Layout.preferredHeight: 232
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
                                    implicitHeight: 38

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
                                        scale: cell.isSelected ? 1 : 0.6
                                        Behavior on scale {
                                            NumberAnimation { duration: Theme.animation.fast; easing.type: Easing.OutBack }
                                        }
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

                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 4
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
                        }

                        Rectangle {
                            Layout.fillHeight: true
                            Layout.topMargin: Theme.spacing.tiny
                            Layout.bottomMargin: Theme.spacing.tiny
                            implicitWidth: 1
                            color: Theme.colors.borderSubtle
                            opacity: 0.5
                        }

                        // selected-day agenda
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Text {
                                anchors.centerIn: parent
                                width: parent.width - Theme.spacing.large
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                visible: !GoogleCalendar.connected
                                text: "Connect a Google account in Settings › Calendar to see your events."
                                font.family: Theme.font.main
                                font.pointSize: root.fDate
                                color: Theme.colors.textTertiary
                            }

                            ScrollView {
                                anchors.fill: parent
                                visible: GoogleCalendar.connected
                                clip: true
                                contentWidth: availableWidth
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                                CalAgenda {
                                    width: parent.width
                                    day: root.selectedDate
                                    listCap: 240
                                }
                            }
                        }
                    }
                }

                // ============ PANE 2 — To-do ============
                Item {
                    width: stack.width
                    height: stack.height

                    ScrollView {
                        anchors.fill: parent
                        clip: true
                        contentWidth: availableWidth
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        CalTasks {
                            width: parent.width
                        }
                    }
                }
            }
        }

        // --- whole-view tabs, along the bottom ----------------------
        Rectangle {
            id: tabBar
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.tiny
            implicitHeight: 34
            radius: Theme.rounding.control
            color: Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                           Theme.colors.surfaceVariant.b, 0.5)

            readonly property real segW: (width - 6) / 2

            Rectangle {
                width: tabBar.segW
                height: parent.height - 6
                y: 3
                x: 3 + root.tab * tabBar.segW
                radius: Theme.rounding.control - 3
                color: Theme.colors.surfaceVariant
                Behavior on x {
                    NumberAnimation { duration: Theme.animation.fast; easing.type: Easing.OutCubic }
                }
            }

            Row {
                anchors.fill: parent
                Repeater {
                    model: [
                        { label: "Calendar", glyph: "󰃭" },
                        { label: "To-do",    glyph: "󰄬" }
                    ]
                    delegate: Item {
                        id: tabItem
                        required property int index
                        required property var modelData
                        width: tabBar.segW + 3
                        height: tabBar.height
                        readonly property bool on: root.tab === index

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacing.tiny
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabItem.modelData.glyph
                                font.family: Theme.font.icon
                                font.pointSize: root.fDate
                                color: tabItem.on ? Theme.colors.textPrimary : Theme.colors.textTertiary
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabItem.modelData.label
                                font.family: Theme.font.main
                                font.pointSize: root.fDate
                                font.weight: tabItem.on ? Theme.font.semiBold : Theme.font.regular
                                color: tabItem.on ? Theme.colors.textPrimary : Theme.colors.textTertiary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tab = tabItem.index
                        }
                    }
                }
            }

        }
    }
}
