import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.widgets

// Bar battery indicator: a circular gauge (Theme.widget.circularStyle) whose
// level tracks the charge and whose colour uses the SAME success -> warning ->
// error ramp as the SystemStats RAM gauge (just inverted — a low charge is the
// bad end), with a spark glyph in the centre. It lives in the RIGHT cluster, so
// the percentage sits to the LEFT of the circle (mirrored from the SystemStats
// gauges), tinted to match and in tabular figures. HoverPill gives it its own
// hover wash; a ring overlay pulses while charging.
HoverPill {
    id: root

    spacing: 1

    // Mirror of SystemStats' `Gauge.tint`: three tiers, green when healthy,
    // red at the danger end. Charging is left to the pulsing overlay ring, not
    // a colour, so this reads exactly like the RAM gauge.
    readonly property color tint: Battery.percentage <= 0.20 ? Theme.colors.error
        : Battery.percentage <= 0.40 ? Theme.colors.warning
        : Theme.colors.success

    Text {
        visible: BarConfig.widgetSetting("battery", "showPercent")
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: visible ? powerMetrics.width : 0
        Layout.preferredHeight: Theme.widget.circularSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Math.round(Battery.percentage * 100)
        color: root.tint
        font.family: Theme.font.main
        font.pointSize: Theme.bar.fontSize
        font.weight: Theme.font.semiBold
        font.features: ({ "tnum": 1, "lnum": 1 })

        TextMetrics {
            id: powerMetrics
            text: "100"
            font.family: Theme.font.main
            font.pointSize: Theme.bar.fontSize
            font.weight: Theme.font.semiBold
        }
    }

    CircularWidget {
        id: gauge

        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: Theme.widget.circularSize
        Layout.preferredHeight: Theme.widget.circularSize

        size: Theme.widget.circularSize
        value: Battery.percentage
        progressColor: root.tint

        iconText: "" // nf-fa-bolt (spark)

        overlayVisible: Battery.charging
        overlayColor: Theme.colors.warning
        NumberAnimation on overlayOpacity {
            running: Battery.charging
            loops: Animation.Infinite
            from: 0.3
            to: 1.0
            duration: 1000
        }
    }

    AppTooltip {
        visible: root.hovered && Battery.isLaptopBattery
        delay: 500
        text: {
            var info = Math.round(Battery.percentage * 100) + "%"
            if (Battery.timeRemaining !== "")
                info += "\n" + Battery.timeRemaining
            if (Battery.energyRate > 0.01)
                info += "\n" + Battery.energyRate.toFixed(2) + "W"
            return info
        }
    }
}
