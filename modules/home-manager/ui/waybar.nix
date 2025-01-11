{ pkgs, ... }:

let
  #  ${pkgs.wl-paste}/bin/wl-paste --type text --watch cliphist store &
  # ${pkgs.wl-paste}/bin/wl-paste --type image --watch cliphist store &
  idleToggle = pkgs.pkgs.writeShellScriptBin "idleToggle" ''
    if pgrep -x "hypridle" > /dev/null
    then
        dunstify Hypridle "hypridle is running. Killing process..."
        pkill -x "hypridle"
    else
        dunstify Hypridle "hypridle is not running. Starting process..."
        hypridle &
    fi
  '';
in
{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        margin-top = 0;
        margin-bottom = 0;
        # height = 42;
        layer = "top";
        position = "top";
        # spacing = 15;
        modules-left = [
          "hyprland/workspaces"
          "clock#date"
          "clock"
          "custom/right-arrow"
        ];
        modules-center = [ ];
        modules-right = [
          "custom/left-arrow"
          "tray"
          "wireplumber"
          "battery"
          "idle_inhibitor"
          "custom/lock"
        ];
        "custom/right-arrow" = {
          "format" = "";
          "tooltip" = false;
        };
        "custom/left-arrow" = {
          "format" = "";
          "tooltip" = false;
        };
        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          on-click = "activate";
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
          persistent_workspaces = {
            "1" = "[]";
            "2" = "[]";
            "3" = "[]";
          };
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
          tooltip-format = "";
          tooltip = false;
          on-click = ''${idleToggle}/bin/idleToggle'';
        };

        tray = {
          spacing = 14;
          "icon-size" = 20;
        };

        wireplumber = {
          format = "{icon} {volume}%";
          format-bluetooth = "{icon}  {volume}%";
          format-bluetooth-muted = "  muted";
          format-muted = " muted";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = ''${pkgs.pavucontrol}/bin/pavucontrol'';
          on-click-right = ''${pkgs.blueman}/bin/blueman-manager'';
          # on-click = ''${blueToggle}/bin/blueToggle'';
        };

        battery = {
          bat = "BAT0";
          adapter = "ADP0";
          interval = 60;
          states = {
            warning = 30;
            critical = 15;
          };
          max-length = 10;
          format = "{icon} {capacity}%";
          format-warning = "{icon} {capacity}%";
          format-critical = "{icon} {capacity}%";
          format-plugged = " {capacity}%";
          format-alt = "{icon} {capacity}%";
          format-full = " 100%";
          format-charging = " {capacity}%";
          format-icons = [
            "󰂎"
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
        };

        clock = {
          format = " {:%H:%M}";
        };

        "clock#date" = {
          format = " {:%A, %B %d, %Y}";
        };

        "custom/lock" = {
          format = "";
          tooltip = false;
          on-click = "sleep 0.5; hyprlock";
        };
      };
    };
    style = ''
      * {
          font-family: Ubuntu Nerd Font;
          font-size: 20px;
          background-color: transparent;
      }

      window#waybar {
          background-color: rgba(63, 75, 101, 0.75);
          color: #2d353b;
          transition-property: background-color;
          transition-duration: 0.5s;
          transition-duration: .5s;
      }
      #custom-right-arrow,
      #custom-left-arrow {
      	color: rgba(63, 75, 101, 0.9);
          font-size: 29px;
      }
      #custom-launcher,
      #clock,
      #clock-date,
      #workspaces,
      #wireplumber,
      #network,
      #battery,
      #custom-lock,
      #idle_inhibitor,
      #tray{
          background-color: rgba(63, 75, 101, 0.9);
          color: #e9e9e9;

          padding-left: 10px;
          padding-right: 10px;
      }

      #clock,
      #pulseaudio,
      #memory,
      #cpu,
      #battery,
      #disk {
      	padding: 0 10px;
      }
      #workspaces button:hover {
      	background: #1a1a1a;
      	border: #1a1a1a;
      	padding: 0 3px;
      }
      #workspaces button {
      	padding: 0 2px;
          background-color: rgba(63, 75, 101, 0.70);
          border-radius: 0;
      }
      #workspaces button.active {
          background-color: rgba(127, 187, 179, 0.9);
          color: #2d353b;
      }

    '';
  };
}
