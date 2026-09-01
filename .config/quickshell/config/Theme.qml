pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: theme

    // Live colour scheme — every value comes from the active scheme file via
    // Appearance (default: Catppuccin Mocha). Fallbacks keep the shell readable
    // if a scheme is missing a key.
    readonly property var _p: Appearance.palette
    readonly property QtObject palette: QtObject {
        readonly property color base: theme._p.base ?? "#1e1e2e"
        readonly property color mantle: theme._p.mantle ?? "#181825"
        readonly property color crust: theme._p.crust ?? "#11111b"

        readonly property color surface0: theme._p.surface0 ?? "#313244"
        readonly property color surface1: theme._p.surface1 ?? "#45475a"
        readonly property color surface2: theme._p.surface2 ?? "#585b70"

        readonly property color overlay0: theme._p.overlay0 ?? "#6c7086"
        readonly property color overlay1: theme._p.overlay1 ?? "#7f849c"
        readonly property color overlay2: theme._p.overlay2 ?? "#9399b2"
        readonly property color subtext0: theme._p.subtext0 ?? "#a6adc8"
        readonly property color subtext1: theme._p.subtext1 ?? "#bac2de"
        readonly property color text: theme._p.text ?? "#cdd6f4"

        readonly property color rosewater: theme._p.rosewater ?? "#f5e0dc"
        readonly property color flamingo: theme._p.flamingo ?? "#f2cdcd"
        readonly property color pink: theme._p.pink ?? "#f5c2e7"
        readonly property color mauve: theme._p.mauve ?? "#cba6f7"
        readonly property color red: theme._p.red ?? "#f38ba8"
        readonly property color maroon: theme._p.maroon ?? "#eba0ac"
        readonly property color peach: theme._p.peach ?? "#fab387"
        readonly property color yellow: theme._p.yellow ?? "#f9e2af"
        readonly property color green: theme._p.green ?? "#a6e3a1"
        readonly property color teal: theme._p.teal ?? "#94e2d5"
        readonly property color sky: theme._p.sky ?? "#89dceb"
        readonly property color sapphire: theme._p.sapphire ?? "#74c7ec"
        readonly property color blue: theme._p.blue ?? "#89b4fa"
        readonly property color lavender: theme._p.lavender ?? "#b4befe"
    }

    readonly property QtObject colors: QtObject {
        readonly property color bg: palette.base
        readonly property color fg: palette.text
        readonly property color accent: palette.blue
        readonly property color accentAlt: palette.sapphire
        
        readonly property color surface: palette.surface0
        readonly property color surfaceVariant: palette.surface1
        readonly property color border: palette.surface1
        readonly property color borderSubtle: palette.surface2
        
        readonly property color textPrimary: palette.text
        readonly property color textSecondary: palette.subtext0
        readonly property color textTertiary: palette.overlay0
        
        readonly property color success: palette.green
        readonly property color warning: palette.yellow
        readonly property color error: palette.red
        readonly property color info: palette.blue
        
        readonly property color disabled: palette.overlay0
        readonly property color hover: Qt.rgba(palette.text.r, palette.text.g, palette.text.b, 0.1)
        readonly property color active: Qt.rgba(palette.text.r, palette.text.g, palette.text.b, 0.2)
        
        readonly property color background: bg
        readonly property color text: fg
        readonly property color subtext0: textSecondary
        readonly property color surface0: surface
        readonly property color surface1: surfaceVariant
        readonly property color overlay0: textTertiary
        readonly property color red: error
        readonly property color green: success
        readonly property color yellow: warning
        readonly property color blue: accent
    }

    readonly property QtObject font: QtObject {
        readonly property int tiny: 8
        readonly property int small: 9
        readonly property int normal: 10
        readonly property int medium: 11
        readonly property int large: 12
        readonly property int xlarge: 14
        readonly property int huge: 16
        
        // Two knobs, set in Settings > Appearance:
        //   main  - the UI text font
        //   mono  - the monospace font; it MUST be Nerd-Font-patched because
        //           `icon` is an alias for it (every glyph in the shell comes
        //           from this one family). MonaspiceNe Nerd Font is the default.
        readonly property string main: Appearance.fontFamily || "Rubik"
        readonly property string mono: Appearance.fontMono || "MonaspiceNe Nerd Font"
        readonly property string icon: mono
        
        readonly property int light: Font.Light
        readonly property int regular: Font.Normal
        readonly property int mediumWeight: Font.Medium
        readonly property int semiBold: Font.DemiBold
        readonly property int bold: Font.Bold
    }

    readonly property QtObject fontSize: QtObject {
        readonly property int small: font.small
        readonly property int normal: font.normal
        readonly property int medium: font.medium
        readonly property int large: font.large
        readonly property int xlarge: font.xlarge
    }

    readonly property QtObject spacing: QtObject {
        readonly property int tiny: 4
        readonly property int small: 8
        readonly property int normal: 12
        readonly property int medium: 16
        readonly property int large: 20
        readonly property int xlarge: 24
        readonly property int huge: 32
    }

    readonly property QtObject padding: QtObject {
        readonly property int tiny: 4
        readonly property int small: 6
        readonly property int normal: 8
        readonly property int medium: 10
        readonly property int large: 12
        readonly property int xlarge: 16
        readonly property int huge: 20
    }

    readonly property QtObject rounding: QtObject {
        readonly property int none: 0
        readonly property int small: 6
        readonly property int normal: 8
        readonly property int medium: 10
        readonly property int large: 12
        readonly property int xlarge: 16
        readonly property int huge: 20
        readonly property int full: 9999
    }

    readonly property QtObject animation: QtObject {
        readonly property int instant: 100
        readonly property int fast: 150
        readonly property int normal: 200
        readonly property int medium: 250
        readonly property int slow: 300
        readonly property int verySlow: 400
        
        readonly property var easeOut: Easing.OutCubic
        readonly property var easeIn: Easing.InCubic
        readonly property var easeInOut: Easing.InOutCubic
        readonly property var easeOutQuad: Easing.OutQuad
        readonly property var easeInOutQuad: Easing.InOutQuad
        
        readonly property var easing: Easing.OutCubic
        readonly property var easingInOut: Easing.InOutQuad
        
        readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1.0]
        readonly property var standard: [0.2, 0.0, 0.0, 1.0]
        readonly property var emphasizedAccel: [0.3, 0.0, 0.8, 0.15]
    }
    
    readonly property QtObject bar: QtObject {
        readonly property int height: 50
        readonly property int margin: 10
        readonly property int padding: spacing.normal
        readonly property color background: colors.bg
        
        readonly property int iconSize: 20
        readonly property int buttonSize: 44
        
        readonly property int fontSize: font.large + 1
        readonly property int fontSizeLarge: font.xlarge + 1
        readonly property int fontSizeSmall: font.medium + 1
    }

    // Shared with the screen-edge decoration (ScreenFrame) - the bar's own
    // bottom edge is styled to double as the frame's top run, so both need
    // to agree on the exact same thickness/radius/color.
    readonly property QtObject frame: QtObject {
        readonly property int thickness: 10
        // Outer radius of the frame's corner joint. The content area then
        // curves at cornerRadius - thickness (~24), matching caelestia's
        // border.rounding of 25.
        readonly property int cornerRadius: 34
        // Same color as the bar itself, so the bar's bottom edge and the
        // frame it flows into read as one uninterrupted shape.
        readonly property color color: bar.background
        readonly property color innerColor: "#000000"
    }

    // Floating shell surfaces (the top-left dashboard, the top-centre OSD).
    // `margin` is the single knob for how far any of them sits off the inner
    // edge of the screen-frame border - the dashboard is inset by it on
    // left/top/bottom, the OSD hangs it below the bar - so they all read as
    // an equal, tweakable distance from the frame.
    readonly property QtObject popup: QtObject {
        // Every floating surface (dashboard, OSD) carries the bar's own
        // treatment - the bar background colour, a bar-pill corner radius and
        // no border - just lifted off the desktop with a soft shadow.
        // `margin` is the single knob for how far any of them sits off the
        // bar / frame.
        readonly property int margin: 8
        readonly property int radius: rounding.huge     // matches the section cards inside
        readonly property int padding: theme.padding.xlarge
        readonly property color background: colors.background   // same as the bar strip
        readonly property int borderWidth: 0
        readonly property color border: colors.border
        readonly property color shadow: "#00000060"
        readonly property int osdWidth: 320
        readonly property int osdTimeout: 1500
        // Top-right notification toasts (NotificationPopups) + the dashboard's
        // notification centre share this width; toasts auto-dismiss after
        // notifTimeout unless the notification is Critical.
        readonly property int notifWidth: 380
        readonly property int notifTimeout: 5000
    }

    readonly property QtObject workspace: QtObject {
        // --- shared with BarPill (generic bar-widget capsule) --------------
        readonly property int indicatorHeight: bar.height - 12
        readonly property int indicatorPadding: spacing.small
        // Full stadium — every bar pill is a capsule, not a rounded box.
        readonly property int indicatorRadius: indicatorHeight / 2
        readonly property color background: colors.surface

        // --- workspace chips (WorkspaceIndicator) -------------------------
        // A fixed row of slotCount thin vertical bars in a capsule matching
        // the other bar widgets. Every bar is the same height as the active
        // circle. Four states, four colours:
        //   active     -> activeBg      (the floating accent puck)
        //   occupied   -> occupiedBg    (real workspace with windows, unfocused)
        //   available  -> availableBg   (real workspace, empty - reachable in order)
        //   nonexistent-> nonexistentBg (phantom slot niri doesn't have)
        // The active workspace is a separate puck that slides between slots,
        // stretching to bridge them then pulling back into a circle.
        readonly property int chipH: 26        // bar height AND circle diameter
        readonly property int rectW: 13        // bar width
        readonly property int slotSpacing: spacing.normal
        readonly property int rectRadius: rounding.small
        readonly property int slotCount: 5     // hard cap on shown workspaces

        readonly property color activeBg: colors.accent
        readonly property color availableBg: palette.overlay1
        readonly property color nonexistentBg: palette.mantle
        // "between" active and available - a desaturated accent.
        readonly property color occupiedBg: Qt.rgba(
            (activeBg.r + availableBg.r) / 2,
            (activeBg.g + availableBg.g) / 2,
            (activeBg.b + availableBg.b) / 2,
            1)
    }
    
    readonly property QtObject dashboard: QtObject {
        readonly property int width: 420
        readonly property int height: 700
        readonly property int margin: spacing.medium
        readonly property int padding: spacing.large
        readonly property int itemSpacing: spacing.medium
        
        readonly property color background: colors.bg
        readonly property color cardBackground: colors.surface
    }
    
    // The app launcher's search card (modules/launcher). It wears the same
    // floating-surface treatment as the dashboard and the OSD — `Theme.popup`
    // supplies the background, radius and shadow — so these are only the
    // measurements that are its own.
    readonly property QtObject launcher: QtObject {
        readonly property int width: 640
        readonly property int padding: theme.padding.large
        // How far below the bar the card hangs. Further off than the dashboard
        // sits from the frame: it lands in the middle of your attention rather
        // than tucked into a corner.
        readonly property int topMargin: spacing.huge
        readonly property int searchHeight: 48
        readonly property int rowHeight: 52
        readonly property int iconSize: 32
        // Roughly eight rows. Past that the list scrolls rather than the card
        // growing to fill the screen.
        readonly property int maxListHeight: 430
    }

    readonly property QtObject widget: QtObject {
        readonly property int circularSize: 36
        readonly property int circularStrokeWidth: 3
        readonly property int circularBorderWidth: 1

        // "filled" = end-4 pie-wedge with a knocked-out glyph;
        // "ring"   = the previous thin track + progress arc, glyph drawn solid.
        readonly property string circularStyle: "filled"
        readonly property real circularRingWidth: 3.5

        readonly property color circularBg: colors.bg
        readonly property color circularBorder: colors.surface
        readonly property color iconColor: colors.textPrimary
    }
    
    readonly property QtObject controls: QtObject {
        readonly property int sliderHeight: 3
        readonly property int sliderHandleSize: 18

        // The level bar shared by the dashboard's sliders and the OSD pill
        // (widgets/LevelBar). One set of numbers for all of its styles, so a
        // panel row and the pill under the bar read as the same control: a
        // chunky filled capsule, or a handle on a thin track.
        readonly property int levelThick: 24
        readonly property int levelThin: 6
        readonly property int levelHandle: 14
        // The "icon inside" capsule is taller than the plain one: it has to
        // hold the glyph the other styles keep beside the bar.
        readonly property int levelInline: 36
        // The "split" pair is the slimmest of the lot — with the level and
        // what's left of it drawn as two capsules, the gap between them is
        // what has to read, and a thick bar swallows it.
        readonly property int levelSplit: 8
        readonly property int levelGap: 6

        readonly property int buttonSmall: 25
        readonly property int buttonLarge: 40
        
        readonly property color sliderTrack: colors.surface
        readonly property color sliderProgress: colors.accent
        readonly property color buttonBg: colors.surface
        readonly property color buttonHover: colors.hover
        readonly property color buttonActive: colors.active
    }

    readonly property QtObject sizes: QtObject {
        readonly property int buttonSmall: controls.buttonSmall
        readonly property int buttonLarge: controls.buttonLarge
        readonly property int sliderHeight: controls.sliderHeight
        readonly property int sliderHandleSize: controls.sliderHandleSize
        readonly property int levelThick: controls.levelThick
        readonly property int levelThin: controls.levelThin
        readonly property int levelHandle: controls.levelHandle
        readonly property int levelInline: controls.levelInline
        readonly property int levelSplit: controls.levelSplit
        readonly property int levelGap: controls.levelGap
        readonly property int dashboardWidth: dashboard.width
        readonly property int dashboardHeight: dashboard.height
        readonly property int launcherWidth: launcher.width
    }
}
