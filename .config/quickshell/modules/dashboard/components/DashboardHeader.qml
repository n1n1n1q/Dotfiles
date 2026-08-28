import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config

RowLayout {
    id: root
    
    required property string title
    required property string value
    
    Layout.fillWidth: true
    spacing: Theme.spacing.normal
    
    Text {
        text: root.title
        font.family: Theme.font.main
        font.pointSize: Theme.fontSize.large
        font.bold: true
        color: Theme.colors.text
        Layout.fillWidth: true
    }
    
    Text {
        text: root.value
        font.family: Theme.font.main
        font.pointSize: Theme.fontSize.medium
        color: Theme.colors.subtext0
    }
}
