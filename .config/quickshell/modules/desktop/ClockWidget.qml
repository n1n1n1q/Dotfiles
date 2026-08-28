import QtQuick
import QtQuick.Effects
import qs.config
import qs.services

// Desktop clock. props: format24 (bool), showDate (bool), fontScale (real),
// align (left|center|right).
Item {
    id: root

    property var props: ({})
    readonly property real fs: props.fontScale ?? 1.0
    readonly property bool f24: props.format24 ?? true
    readonly property bool showDate: props.showDate ?? true
    readonly property string align: props.align ?? "center"

    readonly property real gap: Math.round(2 * fs)

    implicitWidth: Math.max(timeT.implicitWidth, dateT.visible ? dateT.implicitWidth : 0)
    implicitHeight: timeT.implicitHeight + (dateT.visible ? dateT.implicitHeight + gap : 0)

    function _x(w) {
        if (root.align === "right") return root.width - w;
        if (root.align === "left") return 0;
        return (root.width - w) / 2;
    }

    // Soft shadow so it stays legible on any wallpaper.
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#99000000"
        shadowBlur: 0.5
        shadowVerticalOffset: 2
        shadowHorizontalOffset: 0
    }

    Text {
        id: timeT
        x: root._x(implicitWidth)
        y: 0
        text: Time.format(root.f24 ? "HH:mm" : "h:mm AP")
        font.family: Theme.font.main
        font.pointSize: Math.round(46 * root.fs)
        font.weight: Theme.font.semiBold
        color: Theme.colors.textPrimary
    }

    Text {
        id: dateT
        x: root._x(implicitWidth)
        y: timeT.height + root.gap
        visible: root.showDate
        text: Time.format("dddd, d MMMM")
        font.family: Theme.font.main
        font.pointSize: Math.round(14 * root.fs)
        color: Theme.colors.textSecondary
    }
}
