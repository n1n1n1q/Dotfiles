import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

Scope {
    // Configuration
    readonly property int frameRounding: 32  // Made larger for better visibility
    readonly property color frameColor: "#1e1e2e"
    readonly property int barHeight: 50  // Match your bar height
    
    // Corner component
    component CornerWindow: PanelWindow {
        id: cornerWindow
        required property ShellScreen screen
        required property int corner // 0=TopLeft, 1=TopRight, 2=BottomLeft, 3=BottomRight
        
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        color: "transparent"
        visible: true
        
        readonly property bool isTopLeft: corner === 0
        readonly property bool isTopRight: corner === 1
        readonly property bool isBottomLeft: corner === 2
        readonly property bool isBottomRight: corner === 3
        readonly property bool isTop: isTopLeft || isTopRight
        readonly property bool isBottom: isBottomLeft || isBottomRight
        readonly property bool isLeft: isTopLeft || isBottomLeft
        readonly property bool isRight: isTopRight || isBottomRight
        
        anchors {
            top: isTop && y == 0  // Only anchor to top if not offset by barHeight
            left: isLeft
            bottom: isBottom
            right: isRight
        }
        
        implicitWidth: frameRounding
        implicitHeight: frameRounding
        
        // Create the corner shape
        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.smooth: true
            preferredRendererType: Shape.CurveRenderer
            
            ShapePath {
                id: shapePath
                strokeWidth: 0
                fillColor: frameColor
                
                startX: cornerWindow.isLeft ? 0 : frameRounding
                startY: cornerWindow.isBottom ? frameRounding : 0
                
                PathAngleArc {
                    moveToStart: false
                    centerX: frameRounding - shapePath.startX
                    centerY: frameRounding - shapePath.startY
                    radiusX: frameRounding
                    radiusY: frameRounding
                    startAngle: {
                        switch (cornerWindow.corner) {
                            case 0: return 180  // TopLeft
                            case 1: return -90  // TopRight
                            case 2: return 90   // BottomLeft
                            case 3: return 0    // BottomRight
                        }
                    }
                    sweepAngle: 90
                }
                
                PathLine {
                    x: shapePath.startX
                    y: shapePath.startY
                }
            }
        }
    }
    
    Variants {
        model: Quickshell.screens
        
        Scope {
            required property ShellScreen modelData
            
            // Top corners positioned under the bar
            PanelWindow {
                screen: modelData
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Bottom
                color: "transparent"
                visible: true
                
                anchors {
                    left: true
                    top: true
                }
                margins.top: barHeight
                implicitWidth: frameRounding
                implicitHeight: frameRounding
                
                // TopLeft corner shape
                Shape {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.smooth: true
                    preferredRendererType: Shape.CurveRenderer
                    
                    ShapePath {
                        strokeWidth: 0
                        fillColor: frameColor
                        startX: 0
                        startY: 0
                        
                        PathAngleArc {
                            moveToStart: false
                            centerX: frameRounding
                            centerY: frameRounding
                            radiusX: frameRounding
                            radiusY: frameRounding
                            startAngle: 180
                            sweepAngle: 90
                        }
                        
                        PathLine { x: 0; y: 0 }
                    }
                }
            }
            
            PanelWindow {
                screen: modelData
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Bottom
                color: "transparent"
                visible: true
                
                anchors {
                    right: true
                    top: true
                }
                margins.top: barHeight
                implicitWidth: frameRounding
                implicitHeight: frameRounding
                
                // TopRight corner shape
                Shape {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.smooth: true
                    preferredRendererType: Shape.CurveRenderer
                    
                    ShapePath {
                        strokeWidth: 0
                        fillColor: frameColor
                        startX: frameRounding
                        startY: 0
                        
                        PathAngleArc {
                            moveToStart: false
                            centerX: 0
                            centerY: frameRounding
                            radiusX: frameRounding
                            radiusY: frameRounding
                            startAngle: -90
                            sweepAngle: 90
                        }
                        
                        PathLine { x: frameRounding; y: 0 }
                    }
                }
            }
            
            // Bottom corners
            CornerWindow {
                screen: modelData
                corner: 2 // BottomLeft
            }
            
            CornerWindow {
                screen: modelData
                corner: 3 // BottomRight
            }
        }
    }
}
