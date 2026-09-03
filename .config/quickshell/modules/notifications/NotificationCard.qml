import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
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
    // Dashboard cards run on the larger dashboard type scale and swap the
    // corner close button for the diagonal swipe-to-delete strip on the right.
    property bool large: false

    signal activated()
    signal dismissRequested()
    signal actionInvoked()

    readonly property int hang: 10
    // The close button only appears once the pointer has settled — and only on
    // toasts; dashboard cards delete through the red strip instead.
    readonly property bool closeReady: showClose && !large && hover.hovered && dwell.armed

    // Type scale: the notch-larger floating-surface scale for both toasts and
    // the centre / stacks, so a toast reads the same size as the panel row it
    // becomes. `large` still governs the delete strip and button, not the type.
    readonly property int fSummary: large ? Theme.dashboard.fontNormal : Theme.popup.fontNormal
    readonly property int fBody: large ? Theme.dashboard.fontSmall : Theme.popup.fontSmall
    readonly property int fMeta: large ? Theme.dashboard.fontTiny : Theme.popup.fontTiny
    readonly property int fIconLetter: large ? Theme.dashboard.fontLarge : Theme.popup.fontMedium

    // Flashes red and collapses while its swipe-out plays. Owned by the service
    // (see Notifications._deleting) so a Repeater rebuild from an unrelated
    // dismiss can't strand a half-deleted card.
    readonly property bool deleting: Notifications.isDeleting(card.entry)

    readonly property int fullHeight: layout.implicitHeight + Theme.padding.large * 2 + hang
    // Collapse to nothing as it fades so the rows below slide up into the gap
    // instead of the list jumping once the entry is finally dropped.
    implicitHeight: deleting ? 0 : fullHeight
    clip: deleting

    opacity: deleting ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: Theme.animation.normal } }
    Behavior on implicitHeight { NumberAnimation { duration: Theme.animation.normal; easing.type: Easing.OutCubic } }

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

        radius: card.flat ? Theme.rounding.control : Theme.rounding.card
        color: card.deleting
            ? Theme.colors.error
            : card.flat
              ? (hover.hovered ? Qt.rgba(Theme.colors.surfaceVariant.r,
                                         Theme.colors.surfaceVariant.g,
                                         Theme.colors.surfaceVariant.b, 0.4)
                               : "transparent")
              : (hover.hovered ? Theme.colors.surfaceVariant : Theme.colors.surface)
        // A solid card gets a hairline so it reads as lifted off the panel /
        // desktop behind it — the fill step alone vanishes on flat dark
        // schemes. A critical one keeps its error outline instead.
        border.width: card.entry.critical ? 1 : (card.flat || card.deleting ? 0 : 1)
        border.color: card.entry.critical ? Theme.colors.error : Theme.colors.hairline

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
            color: Theme.colors.hairline
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
                Layout.preferredWidth: card.large ? 40 : 34
                Layout.preferredHeight: card.large ? 40 : 34
                radius: Theme.rounding.control
                color: Theme.palette.surface2
                clip: true

                Text {
                    anchors.centerIn: parent
                    visible: icon.status !== Image.Ready
                    text: (card.entry.appName || "?").charAt(0).toUpperCase()
                    font.family: Theme.font.main
                    font.pointSize: card.fIconLetter
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
                    // Synchronous: a themed-icon name resolves through Qt's SVG
                    // icon engine, which crashes when hit from the async image
                    // thread (see Tray.qml).
                    asynchronous: false
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
                        font.pointSize: card.fSummary
                        font.weight: Theme.font.semiBold
                        color: Theme.colors.textPrimary
                    }

                    Text {
                        text: Notifications.timeText(card.entry.time)
                        font.family: Theme.font.main
                        font.pointSize: card.fBody
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
                    font.pointSize: card.fBody
                    color: Theme.colors.textSecondary
                }

                Text {
                    visible: card.entry.appName.length > 0
                    text: card.entry.appName
                    font.family: Theme.font.main
                    font.pointSize: card.fMeta
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
                            implicitHeight: card.large ? 30 : 26
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
                                font.pointSize: card.fBody
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

        // Swipe-to-delete affordance: a diagonal ( \ ) red wash bleeding in
        // from the right edge. Fades in while the card is hovered, deepens
        // under its own pointer, and on click flashes the whole card red and
        // dismisses it. Replaces the corner close button on dashboard cards.

        // Masks the strip to the card's own rounded corners — plain `clip`
        // only clips to the bounding box, which left the red squaring off the
        // body's top-right / bottom-right radius.
        Rectangle {
            id: delStripMask
            anchors.fill: delStrip
            visible: false
            layer.enabled: true
            color: "black"
            topRightRadius: body.radius
            bottomRightRadius: body.radius
        }

        Item {
            id: delStrip
            visible: card.large && card.showClose
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: 84
            opacity: card.deleting ? 0 : (delMouse.containsMouse ? 1 : (hover.hovered ? 0.6 : 0))
            Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }

            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: delStripMask
            }

            // A tall rectangle turned -45° so its vertical gradient runs along
            // the "\" diagonal — transparent at the top-left, red at the
            // bottom-right corner of the card.
            Rectangle {
                width: (delStrip.width + delStrip.height) * 1.6
                height: width
                anchors.centerIn: parent
                rotation: -45
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.55; color: "transparent" }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(Theme.colors.error.r, Theme.colors.error.g,
                                       Theme.colors.error.b, 0.9)
                    }
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: Theme.padding.large
                anchors.verticalCenter: parent.verticalCenter
                text: "󰩹"
                font.family: Theme.font.icon
                font.pointSize: card.fSummary
                color: Theme.colors.bg
                opacity: delMouse.containsMouse ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }
            }

            MouseArea {
                id: delMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // A slight drag on the strip must still delete, not get eaten
                // by the dashboard ScrollView's Flickable as the start of a
                // scroll — that was why an expanded group's cards "wouldn't
                // delete".
                preventStealing: true
                onClicked: card.dismissRequested()
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
