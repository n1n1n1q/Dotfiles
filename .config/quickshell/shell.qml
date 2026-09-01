//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
// Drop Qt's client-side titlebar on the settings FloatingWindow (the only
// decorated window we have) - it draws its own close button instead.
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import Quickshell
import qs.modules.bar
import qs.modules.dashboard
import qs.modules.decoration
import qs.modules.desktop
import qs.modules.launcher
import qs.modules.osd
import qs.modules.notifications
import qs.modules.popout
import qs.modules.settings
import qs.services

ShellRoot {
    DesktopLayer {}
    Bar {}
    BarEditOverlay {}
    DashboardLayer {}
    LauncherLayer {}
    ScreenFrame {}
    Osd {}
    NotificationPopups {}
    BarPopout {}
    SettingsWindow {}

    // Touch the Wallpaper singleton so it loads at startup and restores the
    // saved wallpaper through awww.
    QtObject {
        Component.onCompleted: Wallpaper.reload()
    }
}
