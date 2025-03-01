{ ... }:

{
  services.dunst = {
    enable = false;
    settings = {
      global = {
        monitor = 0;
        corner_radius = 10;
        follow = "keyboard";
        width = 370;
        height = 350;
        offset = "20x20";
        padding = 4;
        horizontal_padding = 4;
        font = "Ubuntu 18";
        format = "<b>%s</b>\n%b";
        indicate_hidden = "no";
        notification_limit = 3;
        frame_width = 2;
        gap_size = 6;
        frame_color = "#23424c";
        highlight = "#CDD6F4";
        foreground = "#081425";
        background = "#081425";
        alignment = "left";
        vertical_alignment = "center";
        hide_duplicate_count = true;
        icon_position = "left";
        max_icon_size = 128;
        progress_bar = true;
        progress_bar_max_width = 250;
        progress_bar_corner_radius = 2;
        transparency = 0;
      };
      urgency_low = {
        background = "#181825AA";
        foreground = "#CDD6F4";
        timeout = 10;
      };
      urgency_normal = {
        background = "#181825AA";
        foreground = "#CDD6F4";
        timeout = 10;
      };
      urgency_critical = {
        background = "#181825AA";
        foreground = "#F38BA8";
        frame_color = "#F38BA8";
        timeout = -1;
        format = "<b>%s</b>\n%b";
      };
    };
  };
}
