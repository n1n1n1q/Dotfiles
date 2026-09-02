import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.modules.lock
import qs.modules.settings

// Lock-screen settings — modules/lock. Persisted to lock.json.
SettingsPage {
    id: page
    heading: "Lock screen"
    icon: "󰌾"
    blurb: "A password-protected cover for the session, drawn by the shell "
        + "itself. It can lock on a keybind, after a stretch of no input, or "
        + "just before the machine sleeps — so swayidle isn't needed."

    SettingsGroup {
        caption: "Automatic"
        icon: "󰅶"

        SettingsRow {
            icon: "󰒲"
            title: "Lock when idle"
            subtitle: LockConfig.idleLock
                ? "After a spell of no keyboard or mouse activity"
                : "Only a keybind or IPC locks the screen"
            SettingsToggle {
                checked: LockConfig.idleLock
                onToggled: v => LockConfig.setIdleLock(v)
            }
        }

        SettingsRow {
            icon: "󰔛"
            title: "Idle timeout"
            subtitle: "Minutes of inactivity before the lock appears"
            enabled: LockConfig.idleLock
            SettingsSpin {
                from: 1
                to: 120
                step: 1
                value: Math.round(LockConfig.idleTimeoutSec / 60)
                onStepped: v => LockConfig.setIdleTimeout(v * 60)
            }
        }

        SettingsRow {
            icon: "󰤄"
            title: "Lock before sleep"
            subtitle: "Cover the screen when the system suspends"
            SettingsToggle {
                checked: LockConfig.lockBeforeSleep
                onToggled: v => LockConfig.setLockBeforeSleep(v)
            }
        }

        SettingsRow {
            icon: "󰅶"
            title: "Keep awake"
            subtitle: Caffeine.active
                ? "On — idle-lock, screen-blank and sleep are all held off"
                : "Temporarily hold off idle-lock, screen-blank and sleep (also a dashboard tile / qs ipc call caffeine)"
            SettingsToggle {
                checked: Caffeine.active
                onToggled: v => Caffeine.active = v
            }
        }
    }

    SettingsGroup {
        caption: "Appearance"
        icon: "󰸉"

        SettingsRow {
            icon: "󰝚"
            title: "Show what's playing"
            subtitle: "A now-playing line under the password field"
            SettingsToggle {
                checked: LockConfig.showMedia
                onToggled: v => LockConfig.setShowMedia(v)
            }
        }

        SettingsRow {
            icon: "󰌾"
            title: "Lock now"
            subtitle: "Test it — unlock with your password"
            PillButton {
                text: "Lock"
                onClicked: LockController.lock()
            }
        }
    }
}
