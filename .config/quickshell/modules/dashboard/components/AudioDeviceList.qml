import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services

Rectangle {
    id: root
    
    Layout.fillWidth: true
    Layout.preferredHeight: childrenRect.height + Theme.padding.medium * 2
    color: Theme.colors.surface1
    radius: Theme.rounding.normal
    
    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.padding.normal
        }
        spacing: Theme.spacing.small
        
        Text {
            text: "\udb81\udd7e Output Devices"
            font.family: "Symbols Nerd Font"
            font.pointSize: Theme.fontSize.normal
            font.bold: true
            color: Theme.colors.accent
            Layout.bottomMargin: Theme.spacing.tiny
        }
        
        Repeater {
            model: Audio.sinks
            
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.sizes.buttonLarge
                
                required property var modelData
                property bool isActive: Audio.sink?.id === modelData.id
                
                background: Rectangle {
                    color: parent.isActive ? Theme.colors.accent : 
                           (parent.pressed ? Theme.colors.surface2 : 
                           (parent.hovered ? Theme.colors.overlay0 : Theme.colors.surface0))
                    radius: Theme.rounding.small
                    border.width: parent.isActive ? 2 : 0
                    border.color: Theme.colors.lavender
                }
                
                contentItem: RowLayout {
                    spacing: Theme.spacing.normal
                    anchors.leftMargin: Theme.padding.small
                    anchors.rightMargin: Theme.padding.small
                    
                    Text {
                        text: parent.parent.isActive ? "\uf00c" : "\uf111"
                        font.family: "Symbols Nerd Font"
                        color: parent.parent.isActive ? Theme.colors.base : Theme.colors.accent
                        font.pointSize: Theme.fontSize.xlarge
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                    
                    Text {
                        text: modelData.description || modelData.name || "Unknown Device"
                        color: parent.parent.isActive ? Theme.colors.base : Theme.colors.text
                        font.pointSize: Theme.fontSize.normal
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
                
                onClicked: Audio.setAudioSink(modelData)
            }
        }
    }
}
