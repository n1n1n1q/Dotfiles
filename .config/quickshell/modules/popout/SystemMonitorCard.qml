import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services

// Anchored dropdown for the bar's system gauge: a sortable process list with
// per-row kill, over a compact system-info panel (load, temps, network, disk).
Rectangle {
    id: root

    function fmtBytes(b) {
        if (!b || b < 1024) return (b || 0).toFixed(0) + " B";
        if (b < 1048576) return (b / 1024).toFixed(0) + " KB";
        if (b < 1073741824) return (b / 1048576).toFixed(1) + " MB";
        return (b / 1073741824).toFixed(2) + " GB";
    }

    implicitWidth: 468
    implicitHeight: layout.implicitHeight + Theme.popup.padding * 2
    radius: Theme.popup.radius
    color: Theme.popup.background
    border.width: Theme.popup.borderWidth
    border.color: Theme.popup.border
    clip: true

    // Poll the heavy services only while this card is up.
    Binding { target: Processes;  property: "active"; value: PopoutController.current === "sysmon" }
    Binding { target: SystemInfo; property: "active"; value: PopoutController.current === "sysmon" }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.popup.padding
        spacing: Theme.spacing.small

        Text {
            text: "Processes"
            font.family: Theme.font.main
            font.pointSize: Theme.font.medium
            font.weight: Theme.font.semiBold
            color: Theme.colors.textPrimary
        }

        // --- column headers (sortable) --------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small

            component HCell: Text {
                property string key: ""
                property bool num: false
                font.family: Theme.font.main
                font.pointSize: Theme.font.tiny + 1
                font.weight: Theme.font.semiBold
                color: Processes.sortKey === key ? Theme.colors.accent : Theme.colors.textTertiary
                horizontalAlignment: num ? Text.AlignRight : Text.AlignLeft
                text: {
                    const arrow = Processes.sortKey === key ? (Processes.sortAsc ? "  ↑" : "  ↓") : "";
                    return {"name": "Process", "cpu": "CPU", "mem": "Memory", "pid": "PID"}[key] + arrow;
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Processes.setSort(parent.key)
                }
            }

            HCell { key: "name"; Layout.fillWidth: true }
            HCell { key: "cpu"; num: true; Layout.preferredWidth: 52 }
            HCell { key: "mem"; num: true; Layout.preferredWidth: 76 }
            Item { Layout.preferredWidth: 24 }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.colors.border }

        ListView {
            id: procList
            Layout.fillWidth: true
            Layout.preferredHeight: 208
            clip: true
            model: Processes.sortedList
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: prow
                required property var modelData
                width: procList.width
                height: 30
                color: rowHover.hovered ? Theme.colors.surfaceVariant : "transparent"

                HoverHandler { id: rowHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.rightMargin: Theme.spacing.tiny
                    spacing: Theme.spacing.small

                    Text {
                        Layout.fillWidth: true
                        text: prow.modelData.name
                        elide: Text.ElideRight
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.small
                        color: Theme.colors.textPrimary
                        ToolTip.visible: rowHover.hovered && hovered
                        ToolTip.text: prow.modelData.cmd
                        HoverHandler { id: cmdHover }
                        property bool hovered: cmdHover.hovered
                    }
                    Text {
                        Layout.preferredWidth: 52
                        horizontalAlignment: Text.AlignRight
                        text: prow.modelData.cpu.toFixed(1)
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.small
                        font.features: ({ "tnum": 1 })
                        color: prow.modelData.cpu > 60 ? Theme.colors.error
                            : prow.modelData.cpu > 25 ? Theme.colors.warning
                            : Theme.colors.textSecondary
                    }
                    Text {
                        Layout.preferredWidth: 76
                        horizontalAlignment: Text.AlignRight
                        text: root.fmtBytes(prow.modelData.mem)
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.small
                        font.features: ({ "tnum": 1 })
                        color: Theme.colors.textSecondary
                    }
                    Rectangle {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        radius: Theme.rounding.small
                        opacity: rowHover.hovered ? 1 : 0
                        color: killHover.hovered ? Theme.colors.error : "transparent"
                        Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: Theme.font.icon
                            font.pointSize: Theme.font.small
                            color: killHover.hovered ? Theme.colors.bg : Theme.colors.textTertiary
                        }
                        HoverHandler { id: killHover }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onTapped: (ev, btn) => {
                                if (btn === Qt.RightButton)
                                    Processes.forceKill(prow.modelData.pid);
                                else
                                    Processes.kill(prow.modelData.pid);
                            }
                        }
                        ToolTip.visible: killHover.hovered
                        ToolTip.text: "Kill " + prow.modelData.pid + "  ·  right-click to force"
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: procList.count === 0
                text: "Reading processes…"
                font.family: Theme.font.main
                font.pointSize: Theme.font.small
                color: Theme.colors.textTertiary
            }
        }

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.colors.border }

        // --- system info ---------------------------------------------------
        GridLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.tiny
            columns: 3
            columnSpacing: Theme.spacing.small
            rowSpacing: Theme.spacing.small

            component Stat: Rectangle {
                id: st
                property string label: ""
                property string value: ""
                property string sub: ""
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Theme.rounding.small
                color: Theme.colors.surfaceVariant
                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacing.small
                    anchors.rightMargin: Theme.spacing.small
                    spacing: 0
                    Text {
                        text: st.label
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.tiny
                        color: Theme.colors.textTertiary
                    }
                    Text {
                        text: st.value
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.small
                        font.weight: Theme.font.semiBold
                        font.features: ({ "tnum": 1 })
                        color: Theme.colors.textPrimary
                    }
                    Text {
                        visible: text.length > 0
                        text: st.sub
                        font.family: Theme.font.main
                        font.pointSize: Theme.font.tiny
                        color: Theme.colors.textTertiary
                    }
                }
            }

            Stat { label: "CPU"; value: Math.round(SysResources.cpu * 100) + "%"
                   sub: SystemInfo.cpuTemp > 0 ? SystemInfo.cpuTemp.toFixed(0) + " °C" : "" }
            Stat { label: "RAM"; value: Math.round(SysResources.memory * 100) + "%" }
            Stat { label: "GPU"; value: Math.round(SysResources.gpu * 100) + "%"
                   sub: SystemInfo.gpuTemp > 0 ? SystemInfo.gpuTemp.toFixed(0) + " °C" : "" }

            Stat { label: "↓ Down"; value: root.fmtBytes(SystemInfo.netDown) + "/s"
                   sub: root.fmtBytes(SystemInfo.netDownTotal) }
            Stat { label: "↑ Up"; value: root.fmtBytes(SystemInfo.netUp) + "/s"
                   sub: root.fmtBytes(SystemInfo.netUpTotal) }
            Stat { label: "Disk /"
                   value: SystemInfo.diskTotal > 0
                        ? Math.round(SystemInfo.diskUsed / SystemInfo.diskTotal * 100) + "%" : "—"
                   sub: root.fmtBytes(SystemInfo.diskUsed) + " / " + root.fmtBytes(SystemInfo.diskTotal) }
        }
    }
}
