pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.config
import qs.services

// One output's lock screen: blurred wallpaper, a clock, an avatar and a
// password field, all easing in on lock and reacting to typing / a wrong
// password. `lock` is the modules/lock/Lock scope (shared buffer + PAM).
// Keyboard focus lives on the FocusScope here; every keystroke goes back to
// `lock`. Nothing here touches the unlock / PAM path — it's presentation only.
FocusScope {
    id: root

    required property var lock
    required property string screenName

    // Flipped a frame after load so the entrance transitions have something to
    // animate from.
    property bool entered: false

    focus: true
    Component.onCompleted: {
        forceActiveFocus();
        enterTimer.start();
    }
    Timer {
        id: enterTimer
        interval: 16
        onTriggered: root.entered = true
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.lock.submit();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier)
                root.lock.clearBuffer();
            else
                root.lock.backspace();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            root.lock.clearBuffer();
            event.accepted = true;
        } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 0x20
                   && !(event.modifiers & Qt.ControlModifier)) {
            root.lock.typeChar(event.text);
            event.accepted = true;
        }
    }

    // --- background ------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg
    }

    Image {
        id: wall
        anchors.fill: parent
        source: Wallpaper.current.length > 0 ? ("file://" + Wallpaper.current) : ""
        fillMode: Image.PreserveAspectCrop
        cache: false
        asynchronous: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: wall.status === Image.Ready
        blurEnabled: true
        blur: 1
        blurMax: 64
        // Eases from a light touch to full blur/dim as the screen locks.
        brightness: root.entered ? -0.45 : -0.15
        saturation: root.entered ? -0.3 : 0
        scale: root.entered ? 1 : 1.06
        Behavior on brightness { NumberAnimation { duration: Theme.animation.verySlow; easing.type: Easing.OutCubic } }
        Behavior on saturation { NumberAnimation { duration: Theme.animation.verySlow; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg
        opacity: root.entered ? 0.42 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animation.verySlow } }
    }

    // Any pointer motion keeps focus where the typing needs to be.
    MouseArea {
        anchors.fill: parent
        onPressed: root.forceActiveFocus()
    }

    // --- card ----------------------------------------------------------
    ColumnLayout {
        id: card
        anchors.centerIn: parent
        width: 360
        spacing: Theme.spacing.large

        opacity: root.entered ? 1 : 0
        scale: root.entered ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: Theme.animation.slow; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Theme.animation.slow; easing.type: Easing.OutCubic } }

        transform: Translate {
            y: root.entered ? 0 : 22
            Behavior on y { NumberAnimation { duration: Theme.animation.slow; easing.type: Easing.OutCubic } }
        }

        SequentialAnimation {
            id: shake
            loops: 1
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 14; duration: 45 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -14; duration: 45 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 9; duration: 45 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -5; duration: 45 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0; duration: 45 }
        }

        Connections {
            target: root.lock
            function onFailed() { shake.restart(); errFlash.restart(); }
        }

        // Clock.
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Time.format("HH:mm")
            font.family: Theme.font.main
            font.pointSize: 74
            font.weight: Theme.font.semiBold
            color: Theme.colors.textPrimary
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: -Theme.spacing.medium
            text: Time.format("dddd, d MMMM")
            font.family: Theme.font.main
            font.pointSize: Theme.font.large
            color: Theme.colors.textSecondary
        }

        // Avatar + name.
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.spacing.large
            spacing: Theme.spacing.small

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 76
                implicitHeight: 76
                radius: width / 2
                color: Theme.colors.surfaceVariant
                border.width: 2
                border.color: root.lock.busy
                    ? Theme.colors.accent
                    : root.lock.errorText.length > 0
                      ? Theme.colors.error
                      : Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.4)
                Behavior on border.color { ColorAnimation { duration: Theme.animation.normal } }

                // A soft breathing ring while PAM checks.
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.colors.accent
                    visible: root.lock.busy
                    opacity: 0
                    SequentialAnimation on opacity {
                        running: root.lock.busy
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.6; duration: 700; easing.type: Easing.OutCubic }
                        NumberAnimation { to: 0; duration: 700; easing.type: Easing.InCubic }
                    }
                    SequentialAnimation on scale {
                        running: root.lock.busy
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.25; duration: 1400; easing.type: Easing.OutCubic }
                        PropertyAction { value: 1 }
                    }
                }

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    anchors.margins: 3
                    source: System.userIconPath.length > 0
                        ? ("file://" + System.userIconPath) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }
                MultiEffect {
                    anchors.fill: parent
                    anchors.margins: 3
                    source: avatarImg
                    visible: avatarImg.status === Image.Ready
                    maskEnabled: true
                    maskSource: avatarMask
                }
                Rectangle {
                    id: avatarMask
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: width / 2
                    color: "black"
                    visible: false
                    layer.enabled: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: avatarImg.status !== Image.Ready
                    text: "󰀄"
                    font.family: Theme.font.icon
                    font.pointSize: 32
                    color: Theme.colors.textSecondary
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: System.userName
                font.family: Theme.font.main
                font.pointSize: Theme.font.medium
                color: Theme.colors.textPrimary
            }
        }

        // Password field.
        Rectangle {
            id: field
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.small
            implicitHeight: 48
            radius: height / 2
            color: Theme.colors.surface
            border.width: 1.5
            border.color: root.lock.errorText.length > 0
                ? Theme.colors.error
                : root.lock.buffer.length > 0
                  ? Theme.colors.accent
                  : Theme.colors.borderSubtle
            Behavior on border.color { ColorAnimation { duration: Theme.animation.fast } }

            // Red wash on a wrong password.
            SequentialAnimation {
                id: errFlash
                loops: 1
                ColorAnimation {
                    target: field; property: "color"; duration: 90
                    to: Qt.rgba(Theme.colors.error.r, Theme.colors.error.g, Theme.colors.error.b, 0.22)
                }
                ColorAnimation {
                    target: field; property: "color"; duration: 320
                    to: Theme.colors.surface
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing.large
                anchors.rightMargin: Theme.spacing.small
                spacing: Theme.spacing.small

                Text {
                    text: root.lock.maxedOut ? "󰅚" : root.lock.busy ? "󰔟" : "󰌾"
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.medium
                    color: root.lock.maxedOut ? Theme.colors.error
                        : root.lock.busy ? Theme.colors.accent : Theme.colors.textTertiary
                    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
                }

                // Password dots — each pops in.
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 12

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.lock.buffer.length === 0
                        text: root.lock.maxedOut ? "Locked — wait a moment" : "Enter password"
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.medium
                        color: Theme.colors.textTertiary
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        visible: root.lock.buffer.length > 0

                        Repeater {
                            model: Math.min(root.lock.buffer.length, 32)
                            delegate: Rectangle {
                                id: dot
                                width: 8
                                height: 8
                                radius: 4
                                color: root.lock.errorText.length > 0
                                    ? Theme.colors.error : Theme.colors.textPrimary
                                NumberAnimation {
                                    id: popIn
                                    target: dot
                                    property: "scale"
                                    from: 0; to: 1
                                    duration: Theme.animation.fast
                                    easing.type: Easing.OutBack
                                }
                                Component.onCompleted: popIn.start()
                            }
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: height / 2
                    visible: root.lock.buffer.length > 0
                    scale: visible ? 1 : 0
                    Behavior on scale { NumberAnimation { duration: Theme.animation.fast; easing.type: Easing.OutBack } }
                    color: goMouse.containsMouse ? Theme.colors.accent : Theme.colors.surfaceVariant
                    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰁔"
                        font.family: Theme.font.icon
                        font.pointSize: Theme.font.medium
                        color: goMouse.containsMouse ? Theme.colors.bg : Theme.colors.textPrimary
                    }
                    MouseArea {
                        id: goMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.lock.submit()
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: implicitHeight
            text: root.lock.errorText
            visible: text.length > 0
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            color: Theme.colors.error
        }

        // Media strip (optional).
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.spacing.medium
            spacing: Theme.spacing.small
            visible: LockConfig.showMedia && Media.activePlayer !== null

            Text {
                text: "󰝚"
                font.family: Theme.font.icon
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
            Text {
                text: Media.activePlayer
                    ? (Media.title + (Media.artist.length > 0 ? "  ·  " + Media.artist : ""))
                    : ""
                elide: Text.ElideRight
                Layout.maximumWidth: 320
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textSecondary
            }
        }
    }
}
