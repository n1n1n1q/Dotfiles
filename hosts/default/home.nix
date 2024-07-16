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
    pkgs.zsh
    pkgs.discord
    pkgs.kitty
    pkgs.firefox
    pkgs.neovim
    pkgs.telegram-desktop
    pkgs.zed-editor
    pkgs.neofetch
    pkgs.vscode
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  qt.enable = true;
  qt.platformTheme.name = "adwaita";
  qt.style.package = pkgs.adwaita-qt;
  qt.style.name = "adwaita-dark";


  gtk.enable = true;
  gtk.theme.package = pkgs.gnome-themes-extra;
  gtk.theme.name = "Adwaita-dark";

  programs.home-manager.enable = true;
}
