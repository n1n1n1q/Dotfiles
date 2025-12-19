pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: theme

    readonly property QtObject palette: QtObject {
        readonly property color base: "#1e1e2e"
        readonly property color mantle: "#181825"
        readonly property color crust: "#11111b"
        
        readonly property color surface0: "#313244"
        readonly property color surface1: "#45475a"
        readonly property color surface2: "#585b70"
        
        readonly property color overlay0: "#6c7086"
        readonly property color overlay1: "#7f849c"
        readonly property color overlay2: "#9399b2"
        readonly property color subtext0: "#a6adc8"
        readonly property color subtext1: "#bac2de"
        readonly property color text: "#cdd6f4"
        
        readonly property color rosewater: "#f5e0dc"
        readonly property color flamingo: "#f2cdcd"
        readonly property color pink: "#f5c2e7"
        readonly property color mauve: "#cba6f7"
        readonly property color red: "#f38ba8"
        readonly property color maroon: "#eba0ac"
        readonly property color peach: "#fab387"
        readonly property color yellow: "#f9e2af"
        readonly property color green: "#a6e3a1"
        readonly property color teal: "#94e2d5"
        readonly property color sky: "#89dceb"
        readonly property color sapphire: "#74c7ec"
        readonly property color blue: "#89b4fa"
        readonly property color lavender: "#b4befe"
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
        
        readonly property string main: "Rubik"
        readonly property string mono: "JetBrains Mono NF"
        readonly property string icon: "JetBrains Mono NF"
        
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
        
        readonly property int fontSize: font.large
        readonly property int fontSizeLarge: font.xlarge
        readonly property int fontSizeSmall: font.medium
    }
    
    readonly property QtObject workspace: QtObject {
        readonly property int indicatorHeight: bar.height - (spacing.small * 2)
        readonly property int indicatorSpacing: 0
        readonly property int indicatorPadding: spacing.small
        readonly property int indicatorWidth: 32
        readonly property int indicatorRadius: rounding.xlarge
        
        readonly property color background: colors.surface
        readonly property color activeBg: colors.accent
        readonly property color occupiedBg: colors.surfaceVariant
        readonly property color activeText: colors.bg
        readonly property color occupiedText: colors.textPrimary
        readonly property color emptyText: colors.textTertiary
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
    
    readonly property QtObject widget: QtObject {
        readonly property int circularSize: 32
        readonly property int circularStrokeWidth: 3
        readonly property int circularBorderWidth: 1
        
        readonly property color circularBg: colors.bg
        readonly property color circularBorder: colors.surface
        readonly property color iconColor: colors.textPrimary
    }
    
    readonly property QtObject controls: QtObject {
        readonly property int sliderHeight: 3
        readonly property int sliderHandleSize: 18
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
        readonly property int dashboardWidth: dashboard.width
        readonly property int dashboardHeight: dashboard.height
    }
}
