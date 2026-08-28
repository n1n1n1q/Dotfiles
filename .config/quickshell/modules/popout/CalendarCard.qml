import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

// Anchored dropdown calendar for the bar clock. Month grid from
// QtQuick.Controls (MonthGrid / DayOfWeekRow); scroll or the chevrons page
// months, tapping the title jumps back to today.
Rectangle {
    id: root

    // The month currently shown (always the 1st of that month).
    property date shownMonth: {
        const n = new Date();
        return new Date(n.getFullYear(), n.getMonth(), 1);
    }
    readonly property date today: new Date()

    function step(delta) {
        shownMonth = new Date(shownMonth.getFullYear(), shownMonth.getMonth() + delta, 1);
    }
    function jumpToday() {
        const n = new Date();
        shownMonth = new Date(n.getFullYear(), n.getMonth(), 1);
    }

    implicitWidth: 300
    implicitHeight: col.implicitHeight + Theme.popup.padding * 2
    radius: Theme.popup.radius
    color: Theme.popup.background
    border.width: Theme.popup.borderWidth
    border.color: Theme.popup.border

    WheelHandler {
        acceptedModifiers: Qt.NoModifier
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
                implicitWidth: 28
                implicitHeight: 28
                radius: Theme.rounding.small
                color: nbMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
                Text {
                    anchors.centerIn: parent
                    text: nb.glyph
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.medium
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

            NavBtn { glyph: "󰅁"; onTriggered: root.step(-1) }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 28
                radius: Theme.rounding.small
                color: titleMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
                Text {
                    anchors.centerIn: parent
                    text: root.shownMonth.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.medium
                    font.weight: Theme.font.semiBold
                    color: Theme.colors.textPrimary
                }
                MouseArea {
                    id: titleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.jumpToday()
                }
            }

            NavBtn { glyph: "󰅂"; onTriggered: root.step(1) }
        }

        DayOfWeekRow {
            Layout.fillWidth: true
            locale: grid.locale
            delegate: Text {
                required property var model
                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                font.weight: Theme.font.mediumWeight
                color: (model.day === 0 || model.day === 6)
                    ? Theme.colors.textTertiary : Theme.colors.textSecondary
            }
        }

        MonthGrid {
            id: grid
            Layout.fillWidth: true
            month: root.shownMonth.getMonth()
            year: root.shownMonth.getFullYear()
            locale: Qt.locale()
            spacing: 2

            delegate: Item {
                id: cell
                required property var model
                readonly property bool isToday:
                    model.day === root.today.getDate()
                    && model.month === root.today.getMonth()
                    && model.year === root.today.getFullYear()
                readonly property bool inMonth: model.month === grid.month

                implicitWidth: 34
                implicitHeight: 32

                Rectangle {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    radius: height / 2
                    visible: cell.isToday
                    color: Theme.colors.accent
                }
                Text {
                    anchors.centerIn: parent
                    text: grid.locale.toString(cell.model.day)
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.small
                    font.weight: cell.isToday ? Theme.font.semiBold : Theme.font.regular
                    opacity: cell.inMonth ? 1 : 0.35
                    color: cell.isToday
                        ? Theme.colors.bg
                        : ((cell.model.date.getDay() === 0 || cell.model.date.getDay() === 6)
                            ? Theme.colors.textTertiary : Theme.colors.textPrimary)
                }
            }
        }
    }
}
