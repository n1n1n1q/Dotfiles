{
  pkgs,
  lib,
  config,
  ...
}:

let
  startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
    ${pkgs.bbrShell}/bin/bbrShell &
    ${pkgs.hypridle}/bin/hypridle &
    ${pkgs.hyprpaper}/bin/hyprpaper &
    ${pkgs.wl-clipboard}/bin/wl-paste --type text --watch cliphist store &
    ${pkgs.wl-clipboard}/bin/wl-paste --type image --watch cliphist store &
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
    systemctl start --user polkit-gnome-authentication-agent-1
  '';
in
{
  wayland.windowManager.hyprland = {
    systemd.enableXdgAutostart = true;
    enable = true;
    xwayland.enable = true;
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$fileManager" = "thunar";
      "$menu" = "rofi -show drun";
      monitor = [
        "eDP-1,1920x1080@144,0x0,1"
        "HDMI-A-1,2560x1440@144,1920x-360,1"
      ];
      input = {
        kb_layout = "us,ua";
        kb_options = "grp:alt_shift_toggle";
        follow_mouse = "1";
        touchpad = {
          natural_scroll = "yes";
        };
        sensitivity = "0"; # -1.0 - 1.0, 0 means no modification.
      };

      general = {
        gaps_in = "10";
        gaps_out = "10";

        border_size = "3";
        "col.active_border" = "rgb(48a0ff)"; # 4d
        "col.inactive_border" = "rgb(595959)"; # aa
        layout = "dwindle";
        allow_tearing = "false";
      };

      decoration = {
        rounding = "7";
        blurls = [
          "gtk-layer-shell"
          "waybar"
        ];
        blur = {
          enabled = "true";
          size = "8";
          passes = "3";
          new_optimizations = "on";
        };
        shadow = {
          enabled = "false";
        };
        active_opacity = "0.9";
        inactive_opacity = "0.8";
        fullscreen_opacity = "1";
      };
      animations = {
        enabled = "yes";
        bezier = [
          "defaultBezier, 0.05, 0.9, 0.1, 1.05"
          "workspaceBezier, 0.12,0.95,0.3,1.05"
          "linear, 0.0, 0.0, 1.0, 1.0"
        ];

        animation = [
          "windows, 1, 6, defaultBezier, slide"
          "windowsOut, 1, 10, defaultBezier, popin 80%"
          "fade, 1, 7, defaultBezier"
          "workspaces, 1, 5.5, workspaceBezier, slidevert"
        ];
      };

      dwindle = {
        pseudotile = "yes";
        preserve_split = "yes";
        force_split = "2";
      };

      master = {
        new_on_top = "true";
      };

      gestures = {
        workspace_swipe = "on";
        workspace_swipe_fingers = "3";
      };

      windowrule = [
        "opacity 0.8 0.8,^(rofi)$"
        "opacity 0.8 0.7,^(kitty)$"
        "idleinhibit fullscreen,^(firefox)$"
        "idleinhibit fullscreen,^(zen)$"
        "idleinhibit always,^(spotify)$"

      ];

      exec-once = ''${startupScript}/bin/start'';

      bind = [
        "$mod, P, exec, ${startupScript}/bin/start"
        "$mod, R, exec, kitty"
        "$mod, Q, killactive"
        "$mod, M, exec, wlogout"
        "$mod, E, exec, thunar"
        "$mod, space, togglefloating"
        "$mod, C, exec, $menu"
        "$mod, P, pseudo"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        "$mod&SHIFT,S,exec,grim -g \"$(slurp)\" - | swappy -f -"
        ",Print,exec,grim -g \"$(slurp)\" - | swappy -f -"
        "$mod SHIFT,D,exec,hyprshot-gui"
        "$mod,Print,exec,hyprshot-gui"
        "$mod,Tab,exec, rofi -show window"
        "$mod SHIFT, Tab, exec, ~/.config/scripts/wallpaper.sh"
        "ALT, Tab, cyclenext"
        "ALT,Tab,bringactivetotop"
        "$mod SHIFT, N, exec, swaync-client -t -sw"
        "$mod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"
      ];
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
      binde = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 2 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume -l 2 @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ",XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ",XF86KbdBrightnessDown, exec, brightnessctl -d asus::kbd_backlight s 1-"
        ",XF86KbdBrightnessUp, exec, brightnessctl -d asus::kbd_backlight s +1"
      ];
    };
  };
}
