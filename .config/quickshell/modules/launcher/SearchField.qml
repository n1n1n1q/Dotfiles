import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

// The launcher's input line. It owns the keyboard for the whole surface —
// everything below it is a list you steer, not something you focus — so the
// arrow keys, Enter and Escape are all handled here and passed up.
Rectangle {
    id: root

    signal accepted()
    signal dismissed()

    implicitHeight: Theme.launcher.searchHeight
    radius: height / 2
    color: Theme.colors.surface

    readonly property var mode: LauncherController.mode

    function takeFocus() { field.forceActiveFocus(); }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing.large
        anchors.rightMargin: Theme.spacing.small
        spacing: Theme.spacing.normal

        // The glyph doubles as the mode indicator: a plain magnifier while
        // you're searching apps, the mode's own icon once a prefix has taken
        // the query somewhere else.
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.mode ? root.mode.icon : "󰍉"
            font.family: Theme.font.icon
            font.pointSize: Theme.font.xlarge
            color: root.mode ? Theme.colors.accent : Theme.colors.textTertiary

            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
        }

        TextField {
            id: field

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            placeholderText: "Search"
            color: Theme.colors.textPrimary
            placeholderTextColor: Theme.colors.textTertiary
            font.family: Theme.font.main
            font.pointSize: Theme.font.large
            leftPadding: 0
            rightPadding: 0
            background: Item {}

            onTextChanged: LauncherController.query = text

            // The controller rewrites the query itself when the launcher is
            // reset or a mode chip retargets a half-typed line; the guard is
            // what keeps that from bouncing back as another edit.
            Connections {
                target: LauncherController
                function onQueryChanged() {
                    if (field.text !== LauncherController.query)
                        field.text = LauncherController.query;
                }
            }

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Escape:
                    root.dismissed();
                    event.accepted = true;
                    return;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    root.accepted();
                    event.accepted = true;
                    return;
                case Qt.Key_Down:
                    LauncherController.move(1);
                    event.accepted = true;
                    return;
                case Qt.Key_Up:
                    LauncherController.move(-1);
                    event.accepted = true;
                    return;
                case Qt.Key_PageDown:
                    LauncherController.move(5);
                    event.accepted = true;
                    return;
                case Qt.Key_PageUp:
                    LauncherController.move(-5);
                    event.accepted = true;
                    return;
                // Tab walks the list rather than the focus chain: there is
                // nothing else on this surface to focus.
                case Qt.Key_Tab:
                    LauncherController.move(1);
                    event.accepted = true;
                    return;
                case Qt.Key_Backtab:
                    LauncherController.move(-1);
                    event.accepted = true;
                    return;
                }

                // The readline pair, for hands that never leave the home row.
                if (event.modifiers & Qt.ControlModifier) {
                    if (event.key === Qt.Key_J) {
                        LauncherController.move(1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_K) {
                        LauncherController.move(-1);
                        event.accepted = true;
                    }
                }
            }
        }

        // Count while there's a list to count, a clear button once there's
        // something to clear — never both, they'd be saying the same thing.
        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: Theme.spacing.small
            visible: field.text.length === 0 && LauncherController.count > 0
            text: LauncherController.count + " apps"
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            color: Theme.colors.textTertiary
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            visible: field.text.length > 0
            implicitWidth: 30
            implicitHeight: 30
            radius: height / 2
            color: clear.containsMouse ? Theme.colors.surfaceVariant : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

            Text {
                anchors.centerIn: parent
                text: "󰅖"
                font.family: Theme.font.icon
                font.pointSize: Theme.font.medium
                color: Theme.colors.textSecondary
            }

            MouseArea {
                id: clear
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    LauncherController.reset();
                    root.takeFocus();
                }
            }
        }
    }
}
