import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// One notification, laid out the same whether it's a corner toast or a row in
// the dashboard's notification centre. Purely presentational: it reads an
// `entry` from the Notifications service and emits signals - the caller
// decides what they mean.
//
//   activated()        - left-click on the card body (jump to the app)
//   dismissRequested() - the close button, or a right-click on the body
//   actionInvoked()    - one of the notification's own action buttons
//
// The close button is macOS-style: nothing is drawn until the pointer has
// rested on the card for DashboardConfig.notifCloseDelay, then a small ⊗ fades
// in straddling the top-right corner. `hang` is the transparent gutter the
// card keeps around its body so that overhang stays inside the item's own
// bounds - the toast window's input mask is only as big as the cards.
Item {
    id: card

    required property var entry
    property bool showClose: true
    // Flat rows for the notification centre's list: no card of their own, just
    // a hover wash and a hairline between them. Toasts and grouped stacks stay
    // solid — a floating card needs its own ground, and the collapsed stack
    // needs something for its slivers to peek out from behind.
    property bool flat: false
    property bool showDivider: false

    signal activated()
    signal dismissRequested()
    signal actionInvoked()

    readonly property int hang: 10
    // The close button only appears once the pointer has settled.
    readonly property bool closeReady: showClose && hover.hovered && dwell.armed

    implicitHeight: layout.implicitHeight + Theme.padding.large * 2 + hang

    HoverHandler { id: hover }

    Timer {
        id: dwell
        property bool armed: false
        interval: Math.max(0, DashboardConfig.notifCloseDelay)
        running: hover.hovered && card.showClose
        onTriggered: armed = true
        onRunningChanged: if (!running) armed = false
    }

    Rectangle {
        id: body

        anchors.fill: parent
        anchors.topMargin: card.hang
        anchors.rightMargin: card.hang

        radius: card.flat ? Theme.rounding.large : Theme.rounding.huge
        color: card.flat
            ? (hover.hovered ? Qt.rgba(Theme.colors.surfaceVariant.r,
                                       Theme.colors.surfaceVariant.g,
                                       Theme.colors.surfaceVariant.b, 0.4)
                             : "transparent")
            : (hover.hovered ? Theme.colors.surfaceVariant : Theme.colors.surface)
        border.width: card.entry.critical ? 1 : 0
        border.color: Theme.colors.error

        Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

        // Separates one flat row from the next; the last row leaves it off.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: Theme.padding.large
            anchors.rightMargin: Theme.padding.large
            height: 1
            visible: card.flat && card.showDivider
            color: Qt.rgba(Theme.colors.borderSubtle.r, Theme.colors.borderSubtle.g,
                           Theme.colors.borderSubtle.b, 0.4)
        }

        // Sits under the content: clicks that don't land on an action button or
        // the close button fall through to here.
        MouseArea {
            id: bodyMouse
            anchors.fill: parent
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

            // Always drawn, so a run of notifications keeps one text margin
            // whether or not each app supplied an icon. Without one it falls
            // back to the source's initial.
            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: Theme.rounding.medium
                color: Qt.rgba(Theme.colors.surfaceVariant.r, Theme.colors.surfaceVariant.g,
                               Theme.colors.surfaceVariant.b, 0.5)
                clip: true

                Text {
                    anchors.centerIn: parent
                    visible: icon.status !== Image.Ready
                    text: (card.entry.appName || "?").charAt(0).toUpperCase()
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.medium
                    font.weight: Theme.font.mediumWeight
                    color: Theme.colors.textSecondary
                }

                Image {
                    id: icon
                    anchors.fill: parent
                    visible: status === Image.Ready
                    source: Notifications.iconSource(card.entry)
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 68
                    sourceSize.height: 68
                    asynchronous: true
                }
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
                            implicitHeight: 26
                            radius: height / 2
                            color: actionMouse.containsMouse
                                ? Theme.colors.surfaceVariant
                                : Qt.rgba(Theme.colors.surfaceVariant.r,
                                          Theme.colors.surfaceVariant.g,
                                          Theme.colors.surfaceVariant.b, 0.55)

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
        }
    }

    // macOS-style close: straddles the body's top-right corner, and only once
    // the pointer has dwelt on the card.
    Rectangle {
        id: closeBtn

        width: 20
        height: 20
        radius: width / 2
        x: body.x + body.width - width / 2
        y: body.y - height / 2
        z: 3

        color: closeMouse.containsMouse ? Theme.colors.error : Theme.palette.surface2
        border.width: 1
        border.color: Theme.colors.surface0

        visible: opacity > 0.01
        opacity: card.closeReady ? 1 : 0
        scale: card.closeReady ? 1 : 0.6

        Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }
        Behavior on scale {
            NumberAnimation { duration: Theme.animation.fast; easing.type: Easing.OutBack }
        }

        Text {
            anchors.centerIn: parent
            text: "󰅖"
            font.family: Theme.font.icon
            font.pointSize: Theme.font.small
            color: closeMouse.containsMouse ? Theme.colors.bg : Theme.colors.textPrimary
        }

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            enabled: card.closeReady
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.dismissRequested()
        }
    }
}
