//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
// Skip Qt's "expensive" fallback fonts (large CJK / emoji faces) from the
// application font DB — the shell only ever draws Monaspace / the configured
// UI font, so the fallbacks are pure startup + resident-memory cost.
//@ pragma Env QS_DROP_EXPENSIVE_FONTS=1
// Drop Qt's client-side titlebar on the settings FloatingWindow (the only
// decorated window we have) - it draws its own close button instead.
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import QtQuick
import Quickshell
import qs.modules.bar
import qs.modules.dashboard
import qs.modules.desktop
import qs.modules.display
import qs.modules.drawers
import qs.modules.launcher
import qs.modules.lock
import qs.modules.picker
import qs.modules.popout
import qs.modules.settings
import qs.services

ShellRoot {
    DesktopLayer {}
    Bar {}
    BarEditOverlay {}
    DashboardLayer {}
    LauncherLayer {}
    PickerLayer {}
    Drawers {}
    BarPopout {}
    SettingsWindow {}
    Lock {}
    DisplayMenu {}

    // Touch the Wallpaper singleton so it loads at startup and restores the
    // saved wallpaper through awww.
    QtObject {
        Component.onCompleted: Wallpaper.reload()
    }

    // Touch GoogleCalendar so its startup sync timer arms even before the
    // calendar popout is first opened.
    QtObject {
        Component.onCompleted: GoogleCalendar.syncedAt
    }
}
