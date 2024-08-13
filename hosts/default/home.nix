{ config, pkgs, imports, ... }:

{
  home.username = "oleh";
  home.homeDirectory = "/home/oleh";

  home.stateVersion = "23.11";

  imports = 
  [
    ../../modules/home-manager/default.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  home.packages = [
    pkgs.kitty
    pkgs.fastfetch
    pkgs.firefox
    pkgs.neovim
    pkgs.telegram-desktop pkgs.discord
    pkgs.zed-editor pkgs.vscode pkgs.jetbrains.clion
    pkgs.grim pkgs.slurp pkgs.swappy
    pkgs.cliphist
    pkgs.brightnessctl
    pkgs.wev
    pkgs.spotify
    pkgs.wl-clipboard
    pkgs.xdg-utils pkgs.xdg-desktop-portal pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-hyprland
    pkgs.obs-studio
    pkgs.libsForQt5.qt5.qtwayland pkgs.libsForQt5.qt5ct
    pkgs.bluez pkgs.pavucontrol
    pkgs.xfce.thunar
    pkgs.pywal
    pkgs.rofi-wayland
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    # XCURSOR_SIZE = "24";
    HYPRSHOT_DIR = "~/Pictures/Screenshots/";
    WLR_NO_HARDWARE_CURSORS = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    CLUTTER_BACKEND = "wayland";
    GDK_BACKEND = "wayland,x11";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_SCALE_FACTOR = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    BROWSER = "firefox";
  };
  programs.home-manager.enable = true;
}
