import QtQuick
import QtQuick.Layouts
import qs.config

// Three-level date picker for CalendarCard's title: a 3x4 month grid with
// year steppers; tapping the year opens a 3x4 decade grid. Emits picked() with
// the chosen year + month (0-11).
ColumnLayout {
    id: root

    property int year: new Date().getFullYear()
    property int month: new Date().getMonth()
    property string mode: "months"          // "months" | "years"

    // First year shown in the decade grid.
    property int _decadeStart: year - (year % 12)

    readonly property int fTitle: Theme.bar.fontSize
    readonly property int fCell: Theme.bar.fontSize

    signal picked(int y, int m)

    spacing: Theme.spacing.small

    component NavBtn: Rectangle {
        property string glyph: ""
        signal triggered()
        implicitWidth: 26
        implicitHeight: 26
        radius: Theme.rounding.small
        color: nbMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
        Text {
            anchors.centerIn: parent
            text: parent.glyph
            font.family: Theme.font.icon
            font.pointSize: root.fTitle
            color: Theme.colors.textSecondary
        }
        MouseArea {
            id: nbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.triggered()
        }
    }

    // --- header --------------------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.tiny

        NavBtn {
            glyph: "󰅁"
            onTriggered: root.mode === "months"
                ? root.year--
                : root._decadeStart -= 12
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 26
            radius: Theme.rounding.small
            color: hMouse.containsMouse ? Theme.colors.surfaceVariant : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
            Text {
                anchors.centerIn: parent
                text: root.mode === "months"
                    ? root.year
                    : root._decadeStart + " – " + (root._decadeStart + 11)
                font.family: Theme.font.main
                font.pointSize: root.fTitle
                font.weight: Theme.font.semiBold
                color: Theme.colors.textPrimary
            }
            MouseArea {
                id: hMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.mode === "months") {
                        root._decadeStart = root.year - (root.year % 12);
                        root.mode = "years";
                    } else {
                        root.mode = "months";
                    }
                }
            }
        }

        NavBtn {
            glyph: "󰅂"
            onTriggered: root.mode === "months"
                ? root.year++
                : root._decadeStart += 12
        }
    }

    // --- grid ---------------------------------------------------------
    GridLayout {
        Layout.fillWidth: true
        columns: 3
        rowSpacing: Theme.spacing.tiny
        columnSpacing: Theme.spacing.tiny

        Repeater {
            model: 12
            delegate: Rectangle {
                id: cell
                required property int index

                readonly property bool isMonths: root.mode === "months"
                readonly property int cellYear: root._decadeStart + index
                readonly property bool current: isMonths
                    ? (index === new Date().getMonth() && root.year === new Date().getFullYear())
                    : (cellYear === new Date().getFullYear())
                readonly property bool selected: isMonths
                    ? (index === root.month && root.year === root.year)
                    : (cellYear === root.year)

                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: Theme.rounding.small
                color: cMouse.containsMouse
                    ? Theme.colors.surfaceVariant
                    : (cell.selected ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.18) : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                Text {
                    anchors.centerIn: parent
                    text: cell.isMonths
                        ? Qt.locale().standaloneMonthName(cell.index, Locale.ShortFormat)
                        : cell.cellYear
                    font.family: Theme.font.main
                    font.pointSize: root.fCell
                    font.weight: cell.current ? Theme.font.semiBold : Theme.font.regular
                    color: cell.current ? Theme.colors.accent : Theme.colors.textPrimary
                }

                MouseArea {
                    id: cMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (cell.isMonths) {
                            root.picked(root.year, cell.index);
                        } else {
                            root.year = cell.cellYear;
                            root.mode = "months";
                        }
                    }
                }
            }
        }
    }
}
