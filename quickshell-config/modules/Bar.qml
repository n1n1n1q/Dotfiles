import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import "../components"

Scope {
    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            id: barWindow
            required property ShellScreen modelData
            screen: modelData
            
            anchors {
                top: true
                left: true
                right: true
            }
            
            implicitHeight: Theme.bar.height
            exclusiveZone: implicitHeight
            
            Rectangle {
                anchors.fill: parent
                color: Theme.bar.background
                radius: 0
                
                Item {
                    anchors.fill: parent
                    
                    ConfigButton {
                        anchors {
                            left: parent.left
                            leftMargin: Theme.spacing.medium
                            verticalCenter: parent.verticalCenter
                        }
                        parentWindow: barWindow
                        barHeight: barWindow.implicitHeight
                    }
                    
                    Item {
                        anchors.centerIn: parent
                        implicitWidth: workspaceWidget.implicitWidth
                        implicitHeight: parent.height
                        
                        WorkspaceWidget {
                            id: workspaceWidget
                            anchors.centerIn: parent
                        }
                    }
                    
                    RowLayout {
                        anchors {
                            right: parent.right
                            rightMargin: Theme.spacing.medium
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.spacing.small
                        
                        TimeWidget {
                            Layout.topMargin: Theme.spacing.small
                            Layout.bottomMargin: Theme.spacing.small
                        }
                        
                        CircularVolumeWidget {
                            Layout.topMargin: Theme.spacing.small
                            Layout.bottomMargin: Theme.spacing.small
                        }
                        
                        CircularBatteryWidget {
                            Layout.topMargin: Theme.spacing.small
                            Layout.bottomMargin: Theme.spacing.small
                        }
 
                        Item {
                            Layout.preferredWidth: Theme.bar.buttonSize
                            Layout.preferredHeight: Theme.bar.buttonSize
                            
                            Text {
                                anchors.centerIn: parent
                                text: "\udb80\udc3b"
                                font.family: Theme.font.icon
                                font.pixelSize: parent.height * 0.8
                                color: appsMouseArea.containsMouse ? Theme.colors.accent : Theme.colors.textPrimary
                                
                                Behavior on color {
                                    ColorAnimation { 
                                        duration: Theme.animation.fast
                                        easing.type: Theme.animation.easeOut
                                    }
                                }
                            }
                            
                            MouseArea {
                                id: appsMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: console.log("Apps icon clicked")
                            }
                        }
                    }
                }
            }
        }
    }
}
