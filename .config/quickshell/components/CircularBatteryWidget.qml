import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
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
            
            value: Battery.percentage
            progressColor: Battery.color
            backgroundColor: Theme.widget.circularBg
            borderColor: Theme.widget.circularBorder
            borderWidth: Theme.widget.circularBorderWidth
            arcThickness: Theme.widget.circularStrokeWidth
            
            iconText: Battery.icon
            iconColor: Theme.widget.iconColor
            iconSize: Theme.bar.fontSize
            
            // Charging indicator animation
            overlayVisible: Battery.charging
            overlayColor: Theme.colors.warning
            
            NumberAnimation on overlayOpacity {
                running: Battery.charging
                loops: Animation.Infinite
                from: 0.3
                to: 1.0
                duration: 1000
            }
            
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    console.log("Battery:", Math.round(Battery.percentage * 100) + "%", 
                               Battery.charging ? "charging" : "discharging")
                }
                
                ToolTip.visible: containsMouse && Battery.isLaptopBattery
                ToolTip.delay: 500
                ToolTip.text: {
                    var info = Math.round(Battery.percentage * 100) + "%"
                    if (Battery.timeRemaining !== "")
                        info += "\n" + Battery.timeRemaining
                    if (Battery.energyRate > 0.01)
                        info += "\n" + Battery.energyRate.toFixed(2) + "W"
                    return info
                }
            }
        }
        
        Text {
            text: Math.round(Battery.percentage * 100) + "%"
            font.pointSize: Theme.bar.fontSize
            color: Theme.colors.textPrimary
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
