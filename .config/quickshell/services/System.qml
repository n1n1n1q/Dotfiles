pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root

    property string userName: Quickshell.env("USER") || "user"

    // Profile picture: whatever the user picked in Settings > General, falling
    // back to the classic ~/.cache/user-icon.
    readonly property string userIconPath: Appearance.avatar.length > 0
        ? Appearance.avatar
        : Quickshell.env("HOME") + "/.cache/user-icon"
}
