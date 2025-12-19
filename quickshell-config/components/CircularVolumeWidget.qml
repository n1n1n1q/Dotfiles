import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import "./base"

Rectangle {
    id: root
    
    implicitWidth: layout.implicitWidth + Theme.workspace.indicatorPadding * 2
    implicitHeight: Theme.workspace.indicatorHeight
    radius: Theme.workspace.indicatorRadius
    color: Theme.workspace.background
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Theme.spacing.tiny
        
        CircularWidget {
            id: widget
            Layout.preferredWidth: Theme.widget.circularSize
            Layout.preferredHeight: Theme.widget.circularSize
        
        size: Theme.widget.circularSize
        value: Audio.volume
        progressColor: Audio.muted ? Theme.colors.error : Theme.colors.success
        backgroundColor: Theme.widget.circularBg
        borderColor: Theme.widget.circularBorder
        borderWidth: Theme.widget.circularBorderWidth
        arcThickness: Theme.widget.circularStrokeWidth
        
        iconText: {
            if (Audio.muted) return "\udb81\udd81"
            if (Audio.volume <= 0.01) return "\udb81\udd81"
            if (Audio.volume <= 0.33) return "\udb81\udd7f"
            if (Audio.volume <= 0.66) return "\udb81\udd80"
            return "\udb81\udd7e"
        }
        iconColor: Theme.widget.iconColor
        iconSize: Theme.bar.fontSize
        
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    Audio.toggleMute()
                }
            }
            
            onWheel: wheel => {
                if (wheel.angleDelta.y > 0) {
                    Audio.incrementVolume()
                } else {
                    Audio.decrementVolume()
                }
            }
        }
    }
        
    Text {
        text: Math.round(Audio.volume * 100) + "%"
        font.pointSize: Theme.bar.fontSize
        color: Theme.colors.textPrimary
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 50
        horizontalAlignment: Text.AlignLeft
    }
    }
}
