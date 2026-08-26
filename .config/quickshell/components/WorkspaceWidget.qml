import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.config
import qs.services

Rectangle {
    id: container
    
    implicitWidth: workspaceRow.implicitWidth + Theme.workspace.indicatorPadding * 2
    implicitHeight: Theme.workspace.indicatorHeight
    radius: Theme.workspace.indicatorRadius
    color: Theme.workspace.background
    
    RowLayout {
        id: workspaceRow
        
        anchors.centerIn: parent
        anchors.margins: Theme.workspace.indicatorPadding
        spacing: Theme.workspace.indicatorSpacing
        
        readonly property int activeWsId: Hyprland.focusedMonitor?.activeWorkspace?.id || 1
        
        // Helper function to check if a workspace is occupied or active
        function isWorkspaceOccupied(id) {
            if (id === activeWsId) return true;
            const workspace = Hyprland.workspaces.values.find(ws => ws.id === id);
            return workspace?.lastIpcObject?.windows > 0 || false;
        }
    
        Repeater {
            model: 9
            
            Rectangle {
                required property int index
                
                readonly property int wsId: index + 1
                readonly property bool isActive: wsId === workspaceRow.activeWsId
                readonly property bool isOccupied: {
                    const workspace = Hyprland.workspaces.values.find(ws => ws.id === wsId);
                    return workspace?.lastIpcObject?.windows > 0 || false;
                }
                readonly property bool hasWindows: isOccupied || isActive
                
                // Check neighbors for edge detection
                readonly property bool hasLeftNeighbor: wsId > 1 && workspaceRow.isWorkspaceOccupied(wsId - 1)
                readonly property bool hasRightNeighbor: wsId < 9 && workspaceRow.isWorkspaceOccupied(wsId + 1)
                
                // Determine border radius based on position and neighbors
                readonly property bool isLeftEdge: hasWindows && !hasLeftNeighbor
                readonly property bool isRightEdge: hasWindows && !hasRightNeighbor
                
                readonly property int indicatorSize: Theme.workspace.indicatorWidth
                readonly property int dotSize: 8
                
                Layout.preferredWidth: indicatorSize
                Layout.preferredHeight: indicatorSize
                
                // Dynamic radius based on position
                radius: {
                    if (!hasWindows) return Theme.rounding.full; // Dot is always round
                    if (isLeftEdge && isRightEdge) return Theme.rounding.full; // Isolated workspace
                    if (isLeftEdge) return Theme.rounding.full; // Left radius only
                    if (isRightEdge) return Theme.rounding.full; // Right radius only
                    return 0; // No radius for middle segments
                }
                
                // Use asymmetric rounding for grouped workspaces
                topLeftRadius: {
                    if (!hasWindows) return radius;
                    if (isLeftEdge) return Theme.rounding.full;
                    return 0;
                }
                topRightRadius: {
                    if (!hasWindows) return radius;
                    if (isRightEdge) return Theme.rounding.full;
                    return 0;
                }
                bottomLeftRadius: {
                    if (!hasWindows) return radius;
                    if (isLeftEdge) return Theme.rounding.full;
                    return 0;
                }
                bottomRightRadius: {
                    if (!hasWindows) return radius;
                    if (isRightEdge) return Theme.rounding.full;
                    return 0;
                }
                
                color: {
                    if (isActive) return Theme.workspace.activeBg
                    if (isOccupied) return Theme.workspace.occupiedBg
                    return Theme.workspace.background
                }
                
                // Active indicator dot
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.dotSize
                    height: parent.dotSize
                    radius: parent.dotSize / 2
                    color: Theme.workspace.activeText
                    visible: parent.isActive
                }
                
                // Workspace number for non-active workspaces
                Text {
                    anchors.centerIn: parent
                    text: parent.wsId
                    font.pointSize: Theme.bar.fontSize
                    font.weight: Theme.font.regular
                    color: {
                        if (parent.isOccupied) return Theme.workspace.occupiedText
                        return Theme.workspace.emptyText
                    }
                    visible: !parent.isActive
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Hyprland.dispatch("workspace " + parent.wsId)
                    }
                }
                
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animation.normal
                        easing.type: Theme.animation.easeOut
                    }
                }
            }
        }
    }
}
