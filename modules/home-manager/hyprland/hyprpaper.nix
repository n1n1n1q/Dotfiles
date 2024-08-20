{services, ...}:

{
    services.hyprpaper = {
        enable = true;
        settings = {
            preload = "/home/oleh/.config/backgrounds/bg016.png";
            wallpaper = [
                "eDP-1,/home/oleh/.config/backgrounds/bg016.png"
                "HDMI-A-1,/home/oleh/.config/backgrounds/bg016.png"
            ];
            ipc = "off";
            splash = true;
        };
    };
}