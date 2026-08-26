import QtQuick
import QtQuick.Controls
import qs.config
import qs.services

Item {
    id: root
    
    width: Theme.bar.buttonSize
    height: Theme.bar.buttonSize
    
    property var dashboardWindow: null
    property var parentWindow: null
    property real barHeight: 50
    
    Text {
        anchors.centerIn: parent
        text: "\ue843"
        font.family: Theme.font.icon
        font.pixelSize: parent.height * 0.8
        color: mouseArea.containsMouse ? Theme.colors.accent : Theme.colors.textPrimary
        
        Behavior on color {
            ColorAnimation { duration: Theme.animation.fast }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            console.log("ConfigButton clicked!")
            if (!dashboardWindow) {
                console.log("Creating dashboard window...")
                let component = Qt.createComponent("DashboardWindow.qml")
                console.log("Component status:", component.status)
                if (component.status === Component.Ready) {
                    dashboardWindow = component.createObject(root, {
                        "screen": parentWindow?.screen,
                        "barHeight": root.barHeight
                    })
                    console.log("Dashboard created:", dashboardWindow)
                    dashboardWindow.show()
                } else if (component.status === Component.Error) {
                    console.error("Error creating dashboard:", component.errorString())
                }
            } else {
                console.log("Toggling existing dashboard")
                dashboardWindow.toggle()
            }
        }
    }
}
