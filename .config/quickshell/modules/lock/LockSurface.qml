pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import qs.config
import qs.services

// One output's lock screen: blurred wallpaper, a clock, and a password field.
// `lock` is the modules/lock/Lock scope (shared buffer + PAM). Keyboard focus
// lives on the FocusScope here; every keystroke goes back to `lock`.
FocusScope {
    id: root

    required property var lock
    required property string screenName

    focus: true
    Component.onCompleted: forceActiveFocus()

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
        brightness: -0.45
        saturation: -0.3
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg
        opacity: 0.42
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

        SequentialAnimation {
            id: shake
            loops: 1
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 12; duration: 45 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -12; duration: 45 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 8; duration: 45 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0; duration: 45 }
        }

        Connections {
            target: root.lock
            function onFailed() { shake.restart(); }
        }

        // Clock.
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Time.format("HH:mm")
            font.family: Theme.font.main
            font.pointSize: 72
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
                implicitWidth: 72
                implicitHeight: 72
                radius: width / 2
                color: Theme.colors.surfaceVariant

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: System.userIconPath.length > 0
                        ? ("file://" + System.userIconPath) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }
                MultiEffect {
                    anchors.fill: parent
                    source: avatarImg
                    visible: avatarImg.status === Image.Ready
                    maskEnabled: true
                    maskSource: avatarMask
                }
                Rectangle {
                    id: avatarMask
                    anchors.fill: parent
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
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.small
            implicitHeight: 46
            radius: height / 2
            color: Theme.colors.surface
            border.width: 1
            border.color: root.lock.errorText.length > 0
                ? Theme.colors.error : "transparent"
            Behavior on border.color { ColorAnimation { duration: Theme.animation.fast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacing.large
                anchors.rightMargin: Theme.spacing.small
                spacing: Theme.spacing.small

                Text {
                    text: root.lock.busy ? "󰔟" : "󰌾"
                    font.family: Theme.font.icon
                    font.pointSize: Theme.font.medium
                    color: Theme.colors.textTertiary
                }

                Text {
                    Layout.fillWidth: true
                    text: root.lock.buffer.length === 0
                        ? "Enter password"
                        : "●".repeat(Math.min(root.lock.buffer.length, 32))
                    elide: Text.ElideRight
                    font.family: Theme.font.main
                    font.pointSize: Theme.font.medium
                    color: root.lock.buffer.length === 0
                        ? Theme.colors.textTertiary : Theme.colors.textPrimary
                }

                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: height / 2
                    visible: root.lock.buffer.length > 0
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
