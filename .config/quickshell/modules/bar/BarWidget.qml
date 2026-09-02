import QtQuick
import qs.config

// Renders a single bar widget by its catalogue id. Sibling widget types live in
// the same module so no import is needed. Unknown ids render nothing.
Loader {
    id: root

    required property string widgetType
    property var panelWindow: null
    property string screenName: ""

    active: true
    visible: status === Loader.Ready

    sourceComponent: {
        switch (widgetType) {
        case "windowTitle": return cWindowTitle;
        case "workspaces":  return cWorkspaces;
        case "workspaceApps": return cWorkspaceApps;
        case "systemStats": return cSystemStats;
        case "media":       return cMedia;
        case "clock":       return cClock;
        case "battery":     return cBattery;
        case "volume":      return cVolume;
        case "connectivity": return cConnectivity;
        case "tray":        return cTray;
        case "spacer":      return cSpacer;
        default:            return null;
        }
    }

    Component { id: cWindowTitle; WindowTitle { parentWindow: root.panelWindow; barHeight: Theme.bar.height } }
    Component { id: cWorkspaces;  WorkspaceIndicator { outputName: root.screenName } }
    Component { id: cWorkspaceApps; WorkspaceApps { outputName: root.screenName } }
    Component { id: cSystemStats; SystemStats { screenName: root.screenName } }
    Component { id: cMedia;       MediaWidget { screenName: root.screenName } }
    Component { id: cClock;       TimeWidget { screenName: root.screenName } }
    Component { id: cBattery;     BatteryWidget {} }
    Component { id: cVolume;      VolumeWidget {} }
    Component { id: cConnectivity; ConnectivityWidget {} }
    Component { id: cTray;        Tray { screenName: root.screenName } }
    Component { id: cSpacer;      SpacerWidget {} }
}
