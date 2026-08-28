import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Clock + date. HoverPill gives it its own hover wash inside the right cluster.
HoverPill {
    id: root

    spacing: Theme.spacing.small

    Text {
        Layout.alignment: Qt.AlignVCenter
        font.family: Theme.font.main
        font.pointSize: Theme.bar.fontSize
        font.weight: Theme.font.semiBold
        color: Theme.colors.textPrimary
        text: Time.timeString
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        font.family: Theme.font.main
        font.pointSize: Theme.bar.fontSize + 2
        color: Theme.colors.textSecondary
        text: "•"
    }

    Text {
        Layout.alignment: Qt.AlignVCenter
        font.family: Theme.font.main
        font.pointSize: Theme.bar.fontSize
        font.weight: Theme.font.regular
        color: Theme.colors.textSecondary
        text: Time.dateString
    }
}
