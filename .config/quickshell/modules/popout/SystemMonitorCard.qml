import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.config
import qs.services
import qs.widgets

// Anchored dropdown for the bar's system gauge. Three big load gauges up top,
// a connected run of throughput / disk rows, then a sortable process list with
// per-row kill. Everything on the shell's own surfaces and radii.
Rectangle {
    id: root

    function fmtBytes(b) {
        if (!b || b < 1024) return (b || 0).toFixed(0) + " B";
        if (b < 1048576) return (b / 1024).toFixed(0) + " KB";
        if (b < 1073741824) return (b / 1048576).toFixed(1) + " MB";
        return (b / 1073741824).toFixed(2) + " GB";
    }

    // success → warning → error, matching the bar gauges.
    function ramp(v) {
        return v > 0.85 ? Theme.colors.error
            : v > 0.6 ? Theme.colors.warning
            : Theme.colors.success;
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
        spacing: Theme.spacing.medium

        // --- header ---------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small

            Text {
                text: "󰓅"
                font.family: Theme.font.icon
                font.pointSize: Theme.popup.fontLarge
                color: Theme.colors.accent
            }
            Text {
                text: "System monitor"
                font.family: Theme.font.main
                font.pointSize: Theme.popup.fontMedium
                font.weight: Theme.font.semiBold
                color: Theme.colors.textPrimary
            }
            Item { Layout.fillWidth: true }
        }

        // --- load gauges --------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing.small

            component Gauge: Rectangle {
                id: g
                property string glyph: ""
                property string label: ""
                property real value: 0
                property string sub: ""
                Layout.fillWidth: true
                implicitHeight: gCol.implicitHeight + Theme.spacing.medium * 2
                radius: Theme.rounding.card
                color: Theme.colors.surfaceVariant

                ColumnLayout {
                    id: gCol
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: Theme.spacing.tiny

                    CircularWidget {
                        Layout.alignment: Qt.AlignHCenter
                        size: 58
                        value: g.value
                        progressColor: root.ramp(g.value)
                        iconText: g.glyph
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Math.round(g.value * 100) + "%"
                        font.family: Theme.font.main
                        font.pointSize: Theme.popup.fontMedium
                        font.weight: Theme.font.semiBold
                        font.features: ({ "tnum": 1 })
                        color: root.ramp(g.value)
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: g.label + (g.sub.length > 0 ? "  ·  " + g.sub : "")
                        font.family: Theme.font.main
                        font.pointSize: Theme.popup.fontTiny
                        color: Theme.colors.textTertiary
                    }
                }
            }

            Gauge {
                glyph: "󰻠"; label: "CPU"; value: SysResources.cpu
                sub: SystemInfo.cpuTemp > 0 ? SystemInfo.cpuTemp.toFixed(0) + "°C" : ""
            }
            Gauge {
                glyph: "󰍛"; label: "RAM"; value: SysResources.memory
            }
            Gauge {
                glyph: "󰢮"; label: "GPU"; value: SysResources.gpu
                sub: SystemInfo.gpuTemp > 0 ? SystemInfo.gpuTemp.toFixed(0) + "°C" : ""
                visible: SysResources.gpuAvailable
            }
        }

        // --- throughput / disk --------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            component InfoRow: Rectangle {
                id: ir
                property string glyph: ""
                property string label: ""
                property string value: ""
                property string sub: ""
                property string blockPos: "middle"   // top | middle | bottom | single
                Layout.fillWidth: true
                implicitHeight: 48
                color: Theme.colors.surfaceVariant

                topLeftRadius: blockPos === "top" || blockPos === "single" ? Theme.rounding.card : Theme.rounding.connJoin
                topRightRadius: topLeftRadius
                bottomLeftRadius: blockPos === "bottom" || blockPos === "single" ? Theme.rounding.card : Theme.rounding.connJoin
                bottomRightRadius: bottomLeftRadius

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacing.small
                    anchors.rightMargin: Theme.spacing.medium
                    spacing: Theme.spacing.small

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: Theme.rounding.control
                        color: Theme.palette.surface2
                        Text {
                            anchors.centerIn: parent
                            text: ir.glyph
                            font.family: Theme.font.icon
                            font.pointSize: Theme.popup.fontMedium
                            color: Theme.colors.textSecondary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: ir.label
                            font.family: Theme.font.main
                            font.pointSize: Theme.popup.fontSmall
                            color: Theme.colors.textPrimary
                        }
                        Text {
                            visible: ir.sub.length > 0
                            text: ir.sub
                            font.family: Theme.font.main
                            font.pointSize: Theme.popup.fontTiny
                            color: Theme.colors.textTertiary
                        }
                    }

                    Text {
                        text: ir.value
                        font.family: Theme.font.main
                        font.pointSize: Theme.popup.fontMedium
                        font.weight: Theme.font.semiBold
                        font.features: ({ "tnum": 1 })
                        color: Theme.colors.textPrimary
                    }
                }
            }

            InfoRow {
                blockPos: "top"
                glyph: "󰇚"; label: "Download"
                value: root.fmtBytes(SystemInfo.netDown) + "/s"
                sub: root.fmtBytes(SystemInfo.netDownTotal) + " this session"
            }
            InfoRow {
                blockPos: "middle"
                glyph: "󰕒"; label: "Upload"
                value: root.fmtBytes(SystemInfo.netUp) + "/s"
                sub: root.fmtBytes(SystemInfo.netUpTotal) + " this session"
            }
            InfoRow {
                blockPos: "bottom"
                glyph: "󰋊"; label: "Disk  /"
                value: SystemInfo.diskTotal > 0
                    ? Math.round(SystemInfo.diskUsed / SystemInfo.diskTotal * 100) + "%" : "—"
                sub: root.fmtBytes(SystemInfo.diskUsed) + " / " + root.fmtBytes(SystemInfo.diskTotal)
            }
        }

        // --- processes ---------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacing.tiny
            spacing: Theme.spacing.small

            Text {
                text: "Processes"
                font.family: Theme.font.main
                font.pointSize: Theme.popup.fontSmall
                font.weight: Theme.font.semiBold
                color: Theme.colors.textSecondary
            }
            Item { Layout.fillWidth: true }

            Repeater {
                model: [
                    { key: "cpu",  label: "CPU" },
                    { key: "mem",  label: "Memory" },
                    { key: "name", label: "Name" }
                ]
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool on: Processes.sortKey === modelData.key
                    implicitWidth: chipRow.implicitWidth + Theme.spacing.small * 2
                    implicitHeight: 22
                    radius: height / 2
                    color: on ? Theme.colors.accentTint : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            text: chip.modelData.label
                            font.family: Theme.font.main
                            font.pointSize: Theme.popup.fontTiny
                            font.weight: chip.on ? Theme.font.semiBold : Theme.font.regular
                            color: chip.on ? Theme.colors.accent : Theme.colors.textTertiary
                        }
                        Text {
                            visible: chip.on
                            text: Processes.sortAsc ? "↑" : "↓"
                            font.family: Theme.font.main
                            font.pointSize: Theme.popup.fontTiny
                            color: Theme.colors.accent
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Processes.setSort(chip.modelData.key)
                    }
                }
            }
        }

        ListView {
            id: procList
            Layout.fillWidth: true
            Layout.preferredHeight: 210
            clip: true
            model: Processes.sortedList
            boundsBehavior: Flickable.StopAtBounds
            spacing: 1
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                id: prow
                required property var modelData
                width: procList.width
                height: 34
                radius: Theme.rounding.small
                color: rowHover.hovered ? Theme.colors.surfaceVariant : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animation.fast } }

                HoverHandler { id: rowHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacing.small
                    anchors.rightMargin: Theme.spacing.tiny
                    spacing: Theme.spacing.small

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Text {
                            Layout.fillWidth: true
                            text: prow.modelData.name
                            elide: Text.ElideRight
                            font.family: Theme.font.main
                            font.pointSize: Theme.popup.fontSmall
                            color: Theme.colors.textPrimary
                            HoverHandler { id: cmdHover }
                            AppTooltip {
                                visible: rowHover.hovered && cmdHover.hovered
                                text: prow.modelData.cmd
                            }
                        }
                        // thin cpu meter — fill only, no track, so a quiet
                        // process is just a short stub rather than a full rule.
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 2
                            Rectangle {
                                width: Math.max(parent.width * Math.max(0, Math.min(1, prow.modelData.cpu / 100)),
                                                prow.modelData.cpu > 0 ? 4 : 0)
                                height: parent.height
                                radius: 1
                                color: prow.modelData.cpu > 60 ? Theme.colors.error
                                    : prow.modelData.cpu > 25 ? Theme.colors.warning
                                    : Theme.mix(Theme.colors.accent, Theme.colors.surfaceVariant, 0.35)
                            }
                        }
                    }

                    Text {
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                        text: prow.modelData.cpu.toFixed(1)
                        font.family: Theme.font.main
                        font.pointSize: Theme.popup.fontSmall
                        font.features: ({ "tnum": 1 })
                        color: prow.modelData.cpu > 60 ? Theme.colors.error
                            : prow.modelData.cpu > 25 ? Theme.colors.warning
                            : Theme.colors.textSecondary
                    }
                    Text {
                        Layout.preferredWidth: 92
                        horizontalAlignment: Text.AlignRight
                        text: root.fmtBytes(prow.modelData.mem)
                        font.family: Theme.font.main
                        font.pointSize: Theme.popup.fontSmall
                        font.features: ({ "tnum": 1 })
                        color: Theme.colors.textSecondary
                    }
                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        radius: Theme.rounding.small
                        opacity: rowHover.hovered ? 1 : 0
                        color: killHover.hovered ? Theme.colors.error : "transparent"
                        Behavior on opacity { NumberAnimation { duration: Theme.animation.fast } }
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: Theme.font.icon
                            font.pointSize: Theme.popup.fontSmall
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
                        AppTooltip {
                            visible: killHover.hovered
                            text: "Kill " + prow.modelData.pid + "  ·  right-click to force"
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: procList.count === 0
                text: "Reading processes…"
                font.family: Theme.font.main
                font.pointSize: Theme.popup.fontSmall
                color: Theme.colors.textTertiary
            }
        }
    }
}
