import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services

RowLayout {
    id: root
    
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignVCenter
    spacing: Theme.spacing.normal
    
    Text {
        text: Audio.muted ? "\udb81\udd81" : "\udb81\udd7e"
        font.family: "Symbols Nerd Font"
        font.pointSize: Theme.fontSize.xlarge
        color: Audio.muted ? Theme.colors.red : Theme.colors.green
        Layout.alignment: Qt.AlignVCenter
    }
    
    Slider {
        id: volumeSlider
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        from: 0
        to: 1
        value: Audio.volume
        stepSize: 0.01
        
        onMoved: Audio.setVolume(value)
        
        background: Rectangle {
            x: volumeSlider.leftPadding
            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
            implicitWidth: 200
            implicitHeight: Theme.sizes.sliderHeight
            width: volumeSlider.availableWidth
            height: implicitHeight
            radius: Theme.rounding.small / 2
            color: Theme.colors.surface1
            
            Rectangle {
                width: volumeSlider.visualPosition * parent.width
                height: parent.height
                color: Audio.muted ? Theme.colors.red : Theme.colors.accent
                radius: Theme.rounding.small / 2
            }
        }
        
        handle: Rectangle {
            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
            implicitWidth: Theme.sizes.sliderHandleSize
            implicitHeight: Theme.sizes.sliderHandleSize
            radius: Theme.rounding.full
            color: volumeSlider.pressed ? Theme.colors.sapphire : Theme.colors.text
            border.color: Audio.muted ? Theme.colors.red : Theme.colors.accent
            border.width: 2
        }
    }
    
    Button {
        Layout.alignment: Qt.AlignVCenter
        text: Audio.muted ? "Unmute" : "Mute"
        font.pointSize: Theme.fontSize.small
        
        background: Rectangle {
            implicitWidth: 60
            implicitHeight: Theme.sizes.buttonSmall
            color: parent.pressed ? Theme.colors.red : (parent.hovered ? Theme.colors.maroon : Theme.colors.surface1)
            radius: Theme.rounding.small
        }
        
        contentItem: Text {
            text: parent.text
            color: Theme.colors.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pointSize: parent.font.pointSize
        }
        
        onClicked: Audio.toggleMute()
    }
}
