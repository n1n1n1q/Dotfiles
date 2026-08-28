import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

GroupBox {
    id: root
    
    required property string headerText
    required property string valueText
    property alias expanded: expandable.expanded
    property alias content: contentLoader.sourceComponent
    
    Layout.fillWidth: true
    title: ""
    
    background: Rectangle {
        color: Theme.colors.surface0
        radius: Theme.rounding.medium
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacing.medium
        
        Item {
            id: expandable
            property bool expanded: false
            
            Layout.fillWidth: true
            height: Theme.sizes.buttonLarge
            
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                
                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.spacing.normal
                    
                    Text {
                        text: root.headerText
                        font.pointSize: Theme.fontSize.large
                        font.bold: true
                        color: Theme.colors.text
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: root.valueText
                        font.pointSize: Theme.fontSize.medium
                        color: Theme.colors.subtext0
                    }
                    
                    Text {
                        text: expandable.expanded ? "\uf077" : "\uf078"
                        font.family: "Symbols Nerd Font"
                        font.pointSize: Theme.fontSize.normal
                        color: Theme.colors.accent
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: expandable.expanded = !expandable.expanded
                }
            }
        }
        
        Loader {
            id: contentLoader
            Layout.fillWidth: true
            active: opacity > 0
            visible: opacity > 0
            opacity: expandable.expanded ? 1 : 0
            
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animation.normal
                    easing.type: Theme.animation.easingInOut
                }
            }
        }
    }
}
