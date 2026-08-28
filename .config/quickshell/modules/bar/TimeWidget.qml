import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets
import qs.modules.popout

// Clock + date. HoverPill gives it its own hover wash inside the right cluster.
// Clicking anywhere on it opens the calendar popout below the bar.
HoverPill {
    id: root

    property string screenName: ""
    spacing: Theme.spacing.small

    clickable: true
    onClicked: {
        const p = mapToItem(null, width / 2, 0);
        PopoutController.toggle("calendar", p.x, width, screenName);
    }

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
