{ services, ... }:

{
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "/home/oleh/.cache/background"
      ];
      wallpaper = [
        "eDP-1,/home/oleh/.cache/background"
        "HDMI-A-1,/home/oleh/.cache/background"
      ];
      ipc = "off";
      # splash = true;
    };
  };
}
