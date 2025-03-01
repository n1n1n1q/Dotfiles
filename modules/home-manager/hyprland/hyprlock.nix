{ programs, ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        grace = 0;
        hide_cursor = true;
      };
      background = {
        monitor = "";
        path = "screenshot";
        #color = rgba(25, 20, 20, 1.0)

        blur_passes = 5;
        blur_size = 7;
        # noise = 0.0117
        # contrast = 0.8916
        # brightness = 0.8172
        # vibrancy = 0.1696
        # vibrancy_darkness = 0.0
      };

      input-field = {
        monitor = "";
        size = "300, 50";
        outline_thickness = 3;
        dots_size = "0.3";
        dots_spacing = "0.3";
        dots_center = true;
        outer_color = "rgba(0,0,0,0)";
        inner_color = "rgb(255,255,255)";
        font_color = "rgb(40, 40, 40)";
        placeholder_color = "rgb(40, 40, 40)";
        font_family = "Mononoki Nerd Font Mono";
        placeholder_text = "<i><span foreground='##282828'>Passwd</span></i>";
        fade_on_empty = false;
        hide_input = false;
        check_color = "rgb(204, 136, 34)";
        fail_color = "rgb(204, 34, 34)";
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
        position = "0, 180";
        halign = "center";
        valign = "bottom";
      };
      label = [
        {
          monitor = "";
          text = "<i>Hi, <b>$USER</b></i>";
          color = "rgba(255, 255, 255, 0.6)";
          font_size = 25;
          font_family = "Mononoki Nerd Font Mono";
          position = "0, 260";
          halign = "center";
          valign = "bottom";
        }
        {
          monitor = "";
          text = "cmd[update:1000] echo \"$(date +\"%-I:%M%p\")\"";
          color = "rgba(255, 255, 255, 0.6)";
          font_size = 120;
          font_family = "Mononoki Nerd Font Mono ExtraBold";
          position = "0, 100";
          halign = "center";
          valign = "center";
        }
        {
          text = "";
          color = "rgba(255, 255, 255, 0.6)";
          font_size = 30;
          font_family = "Mononoki Nerd Font Mono ExtraBold";
          position = "0, 110";
          halign = "center";
          valign = "center";
        }
      ];

      # label = {
      #     $script = "$HOME/.config/hypr/scripts/get_bat.py"
      #     monitor =
      #     text = cmd[update:1000] echo "$($script)"
      #     color = rgba(255, 255, 255, 0.6)
      #     font_size = 30
      #     font_family = Mononoki Nerd Font Mono ExtraBold
      #     position = 0, 50
      #     halign = center
      #     valign = center
      # }
    };
  };
}
