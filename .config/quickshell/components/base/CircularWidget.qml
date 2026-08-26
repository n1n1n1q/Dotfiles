import QtQuick
import QtQuick.Layouts
import qs.config

/**
 * Base reusable circular progress widget
 * Provides a circular arc progress indicator with customizable appearance
 */
Item {
    id: root
    
    // Public properties
    property real value: 0.0  // 0.0 to 1.0
    property color progressColor: Theme.colors.accent
    property color backgroundColor: Theme.colors.background
    property color borderColor: Theme.colors.surface0
    property int size: Theme.bar.iconSize
    property int borderWidth: 1
    property real arcThickness: 3
    property string iconText: ""
    property color iconColor: Theme.colors.text
    property int iconSize: Theme.bar.fontSize
    
    // Optional overlay for special states (e.g., charging animation)
    property alias overlayVisible: overlay.visible
    property alias overlayOpacity: overlay.opacity
    property color overlayColor: Theme.colors.yellow
    
    implicitWidth: size
    implicitHeight: size
    
    // Background circle
    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        radius: Theme.rounding.full
        color: root.backgroundColor
        border.color: root.borderColor
        border.width: root.borderWidth
    }
    
    // Progress arc
    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            
            const centerX = width / 2
            const centerY = height / 2
            const radius = (Math.min(width, height) - root.arcThickness - root.borderWidth * 2) / 2
            
            // Arc settings - start at top (12 o'clock)
            const startAngle = -Math.PI / 2
            const endAngle = startAngle + (2 * Math.PI * root.value)
            
            ctx.lineWidth = root.arcThickness
            ctx.lineCap = "round"
            ctx.strokeStyle = root.progressColor
            
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, startAngle, endAngle, false)
            ctx.stroke()
        }
        
        Connections {
            target: root
            function onValueChanged() { canvas.requestPaint() }
            function onProgressColorChanged() { canvas.requestPaint() }
        }
    }
    
    // Icon/Text in center
    Text {
        anchors.centerIn: parent
        text: root.iconText
        font.family: "Symbols Nerd Font"
        font.pointSize: root.iconSize
        color: root.iconColor
        visible: root.iconText !== ""
    }
    
    // Overlay for animations (e.g., charging indicator)
    Canvas {
        id: overlay
        anchors.fill: parent
        antialiasing: true
        visible: false
        
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            
            const centerX = width / 2
            const centerY = height / 2
            const radius = (Math.min(width, height) - 2) / 2
            
            ctx.lineWidth = 1
            ctx.lineCap = "round"
            ctx.strokeStyle = root.overlayColor
            
            ctx.beginPath()
            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI, false)
            ctx.stroke()
        }
        
        onVisibleChanged: {
            if (visible) requestPaint()
        }
    }
}
