import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services

Rectangle {
    id: root
    
    implicitWidth: layout.implicitWidth + Theme.workspace.indicatorPadding * 2
    implicitHeight: Theme.workspace.indicatorHeight
    radius: Theme.workspace.indicatorRadius
    color: Theme.workspace.background
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Theme.spacing.small
        
        Text {
            font.pointSize: Theme.bar.fontSize
            font.weight: Theme.font.regular
            color: Theme.colors.textPrimary
            text: Time.timeString
        }
        
        Text {
            font.pointSize: Theme.bar.fontSize + 2
            color: Theme.colors.textSecondary
            text: "•"
        }
        
        Text {
            font.pointSize: Theme.bar.fontSize
            font.weight: Theme.font.regular
            color: Theme.colors.textSecondary
            text: Time.dateString
        }
    }
}
