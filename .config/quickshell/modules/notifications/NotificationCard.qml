import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// One notification, laid out the same whether it's a top-right toast or a row
// in the dashboard's notification centre. Purely presentational: it reads an
// `entry` from the Notifications service and emits signals - the caller
// decides what they mean.
//
//   activated()        - left-click on the card body (jump to the app)
//   dismissRequested() - the close button, or a right-click on the body
//   actionInvoked()    - one of the notification's own action buttons
Rectangle {
    id: card

    required property var entry
    property bool showClose: true

    signal activated()
    signal dismissRequested()
    signal actionInvoked()

    implicitHeight: layout.implicitHeight + Theme.padding.large * 2
    radius: Theme.rounding.medium
    color: bodyMouse.containsMouse ? Theme.colors.surface1 : Theme.colors.surface0
    border.width: entry.critical ? 1 : 0
    border.color: Theme.colors.error

    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

    // Sits under the content: clicks that don't land on an action button or
    // the close button fall through to here.
    MouseArea {
        id: bodyMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) card.dismissRequested()
            else card.activated()
        }
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.padding.large
        spacing: Theme.spacing.normal

        Image {
            id: icon
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            visible: source.toString().length > 0 && status === Image.Ready
            source: Notifications.iconSource(card.entry)
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 72
            sourceSize.height: 72
            asynchronous: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.tiny

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacing.small

                Text {
                    Layout.fillWidth: true
                    text: card.entry.summary && card.entry.summary.length > 0
                        ? card.entry.summary : card.entry.appName
                    elide: Text.ElideRight
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.normal
                    font.weight: Theme.font.semiBold
                    color: Theme.colors.textPrimary
                }

                Text {
                    text: Notifications.timeText(card.entry.time)
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.small
                    color: Theme.colors.textTertiary
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: card.entry.body || ""
                textFormat: Text.StyledText  // freedesktop body markup is an HTML subset
                wrapMode: Text.WordWrap
                maximumLineCount: 8
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textSecondary
            }

            Text {
                visible: card.entry.appName.length > 0
                text: card.entry.appName
                font.family: Theme.font.main
                font.pointSize: Theme.font.tiny
                color: Theme.colors.textTertiary
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: actions.count > 0 ? Theme.spacing.tiny : 0
                visible: actions.count > 0
                spacing: Theme.spacing.small

                Repeater {
                    id: actions
                    model: card.entry.notification ? card.entry.notification.actions : []

                    delegate: Rectangle {
                        id: actionBtn
                        required property var modelData

                        implicitWidth: actionLabel.implicitWidth + Theme.padding.large * 2
                        implicitHeight: actionLabel.implicitHeight + Theme.padding.small * 2
                        radius: Theme.rounding.small
                        color: actionMouse.containsMouse
                            ? Theme.colors.surface2 : Theme.colors.surface1

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: actionBtn.modelData.text && actionBtn.modelData.text.length > 0
                                ? actionBtn.modelData.text : actionBtn.modelData.identifier
                            font.family: Theme.font.main
                            font.pointSize: Theme.font.small
                            color: Theme.colors.textPrimary
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                actionBtn.modelData.invoke()
                                card.actionInvoked()
                            }
                        }
                    }
                }
            }
        }

        // Close button - its own rounded hit target so it's easy to click and
        // visibly reacts on hover.
        Rectangle {
            Layout.alignment: Qt.AlignTop
            visible: card.showClose
            implicitWidth: 24
            implicitHeight: 24
            radius: width / 2
            color: closeMouse.containsMouse ? Theme.colors.surface2 : "transparent"

            Text {
                anchors.centerIn: parent
                text: "󰅖"
                font.family: Theme.font.icon
                font.pointSize: Theme.font.normal
                color: closeMouse.containsMouse
                    ? Theme.colors.textPrimary : Theme.colors.textTertiary
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: card.dismissRequested()
            }
        }
    }
}
