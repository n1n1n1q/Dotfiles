import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services

// Compact slider row with changeable icon
Rectangle {
    id: root
    
    required property string sliderIcon
    required property real sliderValue
    required property bool isMuted
    
    signal valueChanged(newValue: real)
    
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
        
        // Empty space for alignment with expandable sliders
        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 24
        }
    }
}
