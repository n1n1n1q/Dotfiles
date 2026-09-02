import QtQuick
import qs.config

// A fixed-width gap. Bar groups size to their content, so this is the way to
// push widgets apart within a group (or to pad a group's edge). Its width is
// the `spacer` widget's `size` setting.
Item {
    implicitWidth: Math.max(1, BarConfig.widgetSetting("spacer", "size"))
    implicitHeight: Theme.workspace.indicatorHeight
}
