import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Desktop system-load widget: CPU / RAM / GPU circular gauges. props:
// showCpu / showRam / showGpu (bool), scale (real).
Item {
    id: root

    property var props: ({})
    readonly property real sc: props.scale ?? 1.0

    implicitWidth: row.implicitWidth + 24 * sc
    implicitHeight: row.implicitHeight + 16 * sc

    Rectangle {
        anchors.fill: parent
        radius: Theme.rounding.large
        color: Qt.rgba(Theme.colors.background.r, Theme.colors.background.g,
                       Theme.colors.background.b, 0.5)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 16 * root.sc

        component Gauge: ColumnLayout {
            id: g
            property real load: 0
            property string glyph: ""
            property string label: ""
            spacing: 2

            CircularWidget {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 44 * root.sc
                Layout.preferredHeight: 44 * root.sc
                size: 44 * root.sc
                value: g.load
                iconText: g.glyph
                progressColor: g.load > 0.85 ? Theme.colors.error
                    : g.load > 0.6 ? Theme.colors.warning : Theme.colors.success
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Math.round(g.load * 100) + "%"
                font.family: Theme.font.main
                font.pointSize: Math.round(11 * root.sc)
                font.weight: Theme.font.semiBold
                color: Theme.colors.textPrimary
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: g.label
                font.family: Theme.font.main
                font.pointSize: Math.round(8 * root.sc)
                color: Theme.colors.textTertiary
            }
        }

        Gauge { visible: root.props.showCpu ?? true;  load: SysResources.cpu;    glyph: "󰻠"; label: "CPU" }
        Gauge { visible: root.props.showRam ?? true;  load: SysResources.memory; glyph: "󰍛"; label: "RAM" }
        Gauge { visible: root.props.showGpu ?? false; load: SysResources.gpu;    glyph: "󰢮"; label: "GPU" }
    }
}
