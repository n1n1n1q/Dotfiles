import QtQuick
import QtQuick.Layouts
import qs.config

// Centred "not built yet" state for sections that are still stubs.
Rectangle {
    id: root

    property string icon: "󰇘"
    property string label: "Coming soon"
    property string hint: ""

    Layout.fillWidth: true
    implicitHeight: 260
    color: Theme.colors.surface
    radius: Theme.rounding.large

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.spacing.large * 2, 380)
        spacing: Theme.spacing.small

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            font.family: Theme.font.icon
            font.pointSize: 40
            color: Theme.colors.textTertiary
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.label
            font.family: Theme.font.main
            font.pointSize: Theme.font.large
            font.weight: Theme.font.semiBold
            color: Theme.colors.textSecondary
        }

        Text {
            visible: root.hint.length > 0
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.hint
            wrapMode: Text.WordWrap
            font.family: Theme.font.main
            font.pointSize: Theme.font.small
            color: Theme.colors.textTertiary
        }
    }
}
