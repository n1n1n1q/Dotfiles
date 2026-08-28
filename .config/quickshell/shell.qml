//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
// Drop Qt's client-side titlebar on the settings FloatingWindow (the only
// decorated window we have) - it draws its own close button instead.
//@ pragma Env QT_WAYLAND_DISABLE_WINDOWDECORATION=1

import Quickshell
import qs.modules.bar
import qs.modules.decoration
import qs.modules.osd
import qs.modules.notifications
import qs.modules.settings

ShellRoot {
    Bar {}
    ScreenFrame {}
    Osd {}
    NotificationPopups {}
    SettingsWindow {}
}
