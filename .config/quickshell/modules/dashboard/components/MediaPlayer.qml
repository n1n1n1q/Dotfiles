import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services

Rectangle {
    id: root
    
    Layout.fillWidth: true
    height: 80
    color: Theme.colors.surface0
    radius: Theme.rounding.medium
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.padding.normal
        spacing: Theme.spacing.normal
        
        Rectangle {
            width: 60
            height: 60
            color: Theme.colors.borderSubtle
            radius: Theme.rounding.small
            
            Text {
                anchors.centerIn: parent
                text: "\udb81\udd67"
                font.family: Theme.font.icon
                font.pointSize: Theme.font.huge
                color: Theme.colors.textPrimary
            }
        }
        
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.tiny
            
            Text {
                text: Media.title || "No media playing"
                color: Theme.colors.textPrimary
                font.family: Theme.font.main
                font.pointSize: Theme.font.medium
                font.weight: Theme.font.bold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            
            Text {
                text: Media.artist || (Media.identity ? `Ready - ${Media.identity}` : "Select a music app to see controls")
                color: Theme.colors.textSecondary
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            
            RowLayout {
                spacing: Theme.spacing.small
                
                Repeater {
                    model: [
                        { icon: "\uf048", canDo: Media.canGoPrevious, action: () => Media.previous() },
                        { icon: Media.isPlaying ? "\uf04c" : "\uf04b", canDo: Media.isPlaying ? Media.canPause : Media.canPlay, action: () => Media.togglePlayPause() },
                        { icon: "\uf051", canDo: Media.canGoNext, action: () => Media.next() }
                    ]
                    
                    Button {
                        text: modelData.icon
                        width: 28
                        height: 28
                        font.family: Theme.font.icon
                        font.pointSize: Theme.font.normal
                        enabled: modelData.canDo
                        
                        background: Rectangle {
                            color: parent.pressed ? Theme.colors.borderSubtle : (parent.hovered ? Theme.colors.textTertiary : "transparent")
                            radius: Theme.rounding.small
                            opacity: parent.enabled ? 1.0 : 0.3
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: Theme.colors.textPrimary
                            font.family: Theme.font.icon
                            font.pointSize: Theme.font.normal
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: modelData.action()
                    }
                }
            }
        }
    }
}
