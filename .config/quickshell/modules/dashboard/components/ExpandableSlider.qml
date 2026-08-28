import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services

// Expandable slider with device list on click
ColumnLayout {
    id: root
    
    required property string sliderIcon
    required property real sliderValue
    required property bool isMuted
    required property var devices
    required property var currentDevice
    
    signal valueChanged(newValue: real)
    signal deviceSelected(device: var)
    
    Layout.fillWidth: true
    spacing: Theme.spacing.small
    
    property bool hovered: false
    property bool expanded: false
    
    // Main slider row
    Rectangle {
        Layout.fillWidth: true
        height: sliderRow.implicitHeight + Theme.padding.small * 2
        color: "transparent"
        radius: Theme.rounding.small
        
        RowLayout {
            id: sliderRow
            anchors.fill: parent
            anchors.margins: Theme.padding.small
            spacing: Theme.spacing.normal
            
            // Icon with fixed width for alignment
            Text {
                text: root.sliderIcon
                font.family: Theme.font.icon
                font.pointSize: Theme.fontSize.xlarge
                color: root.isMuted ? Theme.colors.red : Theme.colors.green
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 32
                horizontalAlignment: Text.AlignHCenter
            }
            
            // Slider
            Slider {
                id: slider
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                from: 0
                to: 1
                value: root.sliderValue
                stepSize: 0.01
                
                onMoved: root.valueChanged(value)
                
                background: Rectangle {
                    x: slider.leftPadding
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: Theme.sizes.sliderHeight
                    width: slider.availableWidth
                    height: implicitHeight
                    radius: Theme.rounding.small / 2
                    color: Theme.colors.surface1
                    
                    Rectangle {
                        width: slider.visualPosition * parent.width
                        height: parent.height
                        color: root.isMuted ? Theme.colors.red : Theme.colors.accent
                        radius: Theme.rounding.small / 2
                    }
                }
                
                handle: Rectangle {
                    x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    implicitWidth: 16
                    implicitHeight: 8
                    radius: 2
                    color: slider.pressed ? Theme.colors.sapphire : Theme.colors.text
                    border.color: root.isMuted ? Theme.colors.red : Theme.colors.accent
                    border.width: 0
                }
            }
            
            // Expand icon button
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
                color: "transparent"
                radius: Theme.rounding.small
                
                Text {
                    anchors.centerIn: parent
                    text: root.expanded ? "󰅀" : "󰅂"
                    font.family: Theme.font.icon
                    font.pointSize: Theme.fontSize.normal
                    color: expandIconArea.containsMouse ? Theme.colors.accent : Theme.colors.subtext0
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animation.fast
                        }
                    }
                }
                
                MouseArea {
                    id: expandIconArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expanded = !root.expanded
                    
                    property bool containsMouse: false
                    onEntered: containsMouse = true
                    onExited: containsMouse = false
                }
            }
        }
    }
    
    // Device list (expandable on click)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.spacing.tiny
        visible: opacity > 0
        opacity: root.expanded ? 1 : 0
        Layout.preferredHeight: root.expanded ? implicitHeight : 0
        clip: true
        
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animation.normal
                easing.type: Theme.animation.easingInOut
            }
        }
        
        Behavior on Layout.preferredHeight {
            NumberAnimation {
                duration: Theme.animation.normal
                easing.type: Theme.animation.easingInOut
            }
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: deviceColumn.height + Theme.padding.medium * 2
            color: Theme.colors.surface1
            radius: Theme.rounding.normal
            
            ColumnLayout {
                id: deviceColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.padding.normal
                spacing: Theme.spacing.small
                
                Repeater {
                    model: root.devices
                    
                    Button {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.sizes.buttonLarge
                        
                        required property var modelData
                        property bool isActive: root.currentDevice?.id === modelData.id
                        
                        background: Rectangle {
                            color: parent.isActive ? Theme.colors.accent : 
                                   (parent.pressed ? Theme.colors.borderSubtle : 
                                   (parent.hovered ? Theme.colors.textTertiary : Theme.colors.surface))
                            radius: Theme.rounding.small
                            border.width: parent.isActive ? 2 : 0
                            border.color: Theme.palette.lavender
                        }
                        
                        contentItem: RowLayout {
                            spacing: Theme.spacing.normal
                            anchors.leftMargin: Theme.padding.small
                            anchors.rightMargin: Theme.padding.small
                            
                            Text {
                                text: parent.parent.isActive ? "" : ""
                                font.family: Theme.font.icon
                                color: parent.parent.isActive ? Theme.colors.bg : Theme.colors.accent
                                font.pointSize: Theme.font.xlarge
                                font.weight: Theme.font.bold
                                Layout.alignment: Qt.AlignVCenter
                            }
                            
                            Text {
                                text: modelData.description || modelData.name || "Unknown Device"
                                color: parent.parent.isActive ? Theme.colors.bg : Theme.colors.textPrimary
                                font.pointSize: Theme.font.normal
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                        
                        onClicked: root.deviceSelected(modelData)
                    }
                }
            }
        }
    }
}
