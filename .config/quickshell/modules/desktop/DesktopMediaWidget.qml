import QtQuick
import qs.config
import qs.widgets

// Desktop now-playing card. The body is the shared MediaLayout, at the tighter
// desktop metrics. props: scale (real), layout (one of MediaLayout's variants).
Item {
    id: root

    property var props: ({})
    readonly property real sc: props.scale ?? 1.0

    implicitWidth: body.implicitWidth
    implicitHeight: body.implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: Theme.rounding.large
        color: Qt.rgba(Theme.colors.background.r, Theme.colors.background.g,
                       Theme.colors.background.b, 0.5)
    }

    MediaLayout {
        id: body
        anchors.fill: parent
        variant: root.props.layout ?? "regular"
        sc: root.sc
        compact: true
        // The desktop layer is click-through at rest, so a switcher here would
        // only be pressable in edit mode.
        showCycle: false
    }
}
