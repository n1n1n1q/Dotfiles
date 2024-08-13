{pkgs, ...}:

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
                height = 42;
                layer= "top";
                position= "top";
                spacing = 15;
                modules-left = ["hyprland/workspaces" "clock#date" "clock"];
                modules-center= [];
                modules-right= ["wireplumber" "battery" "tray" "idle_inhibitor" "custom/lock"];

                "hyprland/workspaces" = {
                    disable-scroll = true;
                    all-outputs = true;
                    on-click = "activate";
                    on-scroll-up = "hyprctl dispatch workspace e+1";
                    on-scroll-down= "hyprctl dispatch workspace e-1";
                    persistent_workspaces = {
                        "1" = "[]";
                        "2" = "[]";
                        "3" = "[]";
                    };
                };
                
                idle_inhibitor = {
                    format= "{icon}";
                        format-icons= {
                            activated = "";
                            deactivated = "";
                    };
                    tooltip-format= "";
                    tooltip= false;
                    on-click = ''${idleToggle}/bin/idleToggle'';
                };
            
                tray= {
                    spacing= 14;
                };
            
                wireplumber = {
                    format= "{icon} {volume}%";
                    format-bluetooth= "{icon}  {volume}%";
                    format-bluetooth-muted= "  muted";
                    format-muted= " muted";
                    format-icons = {
                        headphone= "";
                        hands-free= "";
                        headset= "";
                        phone= "";
                        portable= "";
                        car= "";
                        default= ["" "" ""];
                    };
                    on-click = ''${pkgs.pavucontrol}/bin/pavucontrol'';
                    on-click-right = ''${pkgs.blueman}/bin/blueman-manager'';
                    # on-click = ''${blueToggle}/bin/blueToggle'';
                };
            
                battery= {
                    bat= "BAT0";
                    adapter= "ADP0";
                    interval= 60;
                    states= {
                        warning = 30;
                        critical = 15;
                    };
                    max-length= 10;
                    format= "{icon} {capacity}%";
                    format-warning= "{icon} {capacity}%";
                    format-critical= "{icon} {capacity}%";
                    format-plugged= " {capacity}%";
                    format-alt= "{icon} {capacity}%";
                    format-full= " 100%";
                    format-charging= " {capacity}%";
                    format-icons= [
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
                
                clock= {
                    format= " {:%H:%M}";
                };
                
                "clock#date" = {
                    format= " {:%A, %B %d, %Y}";
                };
                
                "custom/lock" = {
                    format= "";
                    tooltip= false;
                    on-click= "sleep 0.5; hyprlock";
                };
            };
        };
        style = ''
            * {
                font-family: Ubuntu Nerd Font;
                font-size: 16px;
                font-weight: bold;
            }

            window#waybar {
                background-color: rgba(8, 20, 37, 0.6);
                color: #2d353b;
                transition-property: background-color;
                transition-duration: 0.5s;
                transition-duration: .5s;
            }

            #idle_inhibitor,
            #tray,
            #custom-lock{
                margin-left: -15px;
            }
            #battery{
                margin-right: 15px;
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
                background-color: #3F4B65;
                color: #e9e9e9;

                padding-left: 10px;
                padding-right: 10px;
                margin-top: 4px;
                margin-bottom: 7px;
                border-radius: 10px;
            }

            #workspaces {
                padding: 0px;
                margin-left: 15px;

            }

            #workspaces button.active {
                background-color: #7fbbb3;
                color: #2d353b;
                border-radius: 10px;

            }

            #idle_inhibitor {
                border-radius: 0;
            }
            #tray{
                border-radius: 10px 0px 0px 10px;
            }
            #custom-lock {
                margin-right: 15px;
                border-radius: 0px 10px 10px 0px;
            }
        '';
    };
}