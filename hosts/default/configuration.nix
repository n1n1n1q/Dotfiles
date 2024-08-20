#   \\  \\ //
#  ==\\__\\/ //
#    //   \\// 
# ==//     //==
#  //\\___//
# // /\\  \\==
#   // \\  \\ 
{ config, lib, pkgs, inputs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/nixos/default.nix
      inputs.home-manager.nixosModules.default
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking.
  networking.hostName = "nixos"; # Define your hostname.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  systemd.services.wpa_supplicant.environment.OPENSSL_CONF = pkgs.writeText"openssl.cnf"''
openssl_conf = openssl_init
[openssl_init]
ssl_conf = ssl_sect
[ssl_sect]
system_default = system_default_sect
[system_default_sect]
Options = UnsafeLegacyRenegotiation
[system_default_sect]
CipherString = Default:@SECLEVEL=0
'';

  # Set your time zone.
  time.timeZone = "Europe/Kyiv";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "uk_UA.UTF-8";
    LC_IDENTIFICATION = "uk_UA.UTF-8";
    LC_MEASUREMENT = "uk_UA.UTF-8";
    LC_MONETARY = "uk_UA.UTF-8";
    LC_NAME = "uk_UA.UTF-8";
    LC_NUMERIC = "uk_UA.UTF-8";
    LC_PAPER = "uk_UA.UTF-8";
    LC_TELEPHONE = "uk_UA.UTF-8";
    LC_TIME = "uk_UA.UTF-8";
  };

  # Configure keymap in X11
  # services.xserver = {
  #   xkb.layout = "us";
  #   xkb.variant = "";
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.oleh = {
    isNormalUser = true;
    description = "oleh";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git zsh
    hyprpaper hypridle hyprlock hyprcursor
    waybar wofi
    polkit
    polkit_gnome
    networkmanagerapplet
  ];

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    nerdfonts
  ];

  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    users = {
      "oleh" = import ./home.nix;
    };
  };
  stylix = {
    enable = false;
    image = /home/oleh/.config/backgrounds/bg016.png;
    cursor.package = pkgs.bibata-cursors;
    cursor.name = "Bibata-Modern-Ice";
    fonts = {
      monospace = {
        package = pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];};
        name = "CaskaydiaCove Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.nerdfonts.override {fonts = ["UbuntuSans"];};
        name = "Ubuntu Sans Nerd Font";
      };
      serif = {
        package = pkgs.nerdfonts.override {fonts = ["Ubuntu"];};
        name = "Ubuntu Nerd Font";
      };
      sizes = {
        applications = 14;
        terminal = 17;
        desktop = 13;
        popups = 15;
      };
    };
    base16Scheme = {
    base00 = "131f27";
    base01 = "6299AF";
    base02 = "949097";
    base03 = "9C9CA5";
    base04 = "ADAAAF";
    base05 = "DFB4A9";
    base06 = "C7C0C0";
    base07 = "e2e0df";
    base08 = "9e9c9c";
    base09 = "6299AF";
    base0A = "949097";
    base0B = "9C9CA5";
    base0C = "ADAAAF";
    base0D = "DFB4A9";
    base0E = "C7C0C0";
    base0F = "e2e0df";
};
    opacity = {
        applications = 0.9;
        terminal = 0.9;
        desktop = 0.6;
        popups = 1.0;
      };
    polarity = "dark";
  };
  # home-manager.sharedModules = [{
  #   stylix.targets.waybar.enable = false;
  #   stylix.targets.rofi.enable = false;
  #   stylix.targets.hyprland.enable = false;
  #   stylix.targets.dunst.enable = false;
  # }];
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  system.stateVersion = "24.05"; # Did you read the comment?

}

