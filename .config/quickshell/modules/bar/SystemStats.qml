import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.widgets
import qs.modules.popout

// Three circular gauges for CPU / RAM / GPU load, fed by the polled SysResources
// service. The gauge (Theme.widget.circularStyle) tracks the load; its colour
// ramps success -> warning -> error as it climbs; the rounded percentage sits to
// the right (end-4 Resource.qml layout), tinted to match and set in tabular
// figures. HoverPill gives the whole block its own hover wash inside the cluster.
HoverPill {
    id: root

    property string screenName: ""
    spacing: Theme.spacing.small

    clickable: true
    onClicked: {
        const p = mapToItem(null, width / 2, 0);
        PopoutController.toggle("sysmon", p.x, width, screenName);
    }

    component Gauge: RowLayout {
        id: g

        property real load: 0
        property string label: ""
        property string glyph: ""
        readonly property color tint: load > 0.85 ? Theme.colors.error
            : load > 0.6 ? Theme.colors.warning
            : Theme.colors.success

        spacing: 1
        Layout.alignment: Qt.AlignVCenter

        CircularWidget {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Theme.widget.circularSize
            Layout.preferredHeight: Theme.widget.circularSize
            size: Theme.widget.circularSize
            value: g.load
            iconText: g.glyph
            progressColor: g.tint
        }

        Text {
            // Box matches the circle exactly, digits centred in it both ways.
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: numMetrics.width
            Layout.preferredHeight: Theme.widget.circularSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: Math.round(g.load * 100)
            color: g.tint
            font.family: Theme.font.main
            font.pointSize: Theme.bar.fontSize
            font.weight: Theme.font.semiBold
            font.features: ({ "tnum": 1, "lnum": 1 })

            TextMetrics {
                id: numMetrics
                text: "100"
                font.family: Theme.font.main
                font.pointSize: Theme.bar.fontSize
                font.weight: Theme.font.semiBold
            }
        }

        HoverHandler { id: hover }
        ToolTip.visible: hover.hovered
        ToolTip.delay: 400
        ToolTip.text: g.label + " " + Math.round(g.load * 100) + "%"
    }

    // CPU / GPU gauges disabled for now - RAM only.
    Gauge {
        load: SysResources.cpu
        label: "CPU"
        glyph: "󰻠"
        visible: false
    }

    Gauge {
        load: SysResources.memory
        label: "RAM"
        glyph: "󰍛"
    }

    Gauge {
        load: SysResources.gpu
        label: "GPU"
        glyph: "󰢮"
        visible: false // && SysResources.gpuAvailable
    }
}
