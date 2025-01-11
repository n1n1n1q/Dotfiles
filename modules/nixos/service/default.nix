{ lib, ... }:

{
  imports = [
    ./nvidia.nix
    ./pipewire.nix
    ./polkit-agent.nix
    ./power.nix
    ./gdm.nix
    ./bluetooth.nix
    ./networking.nix
  ];
  nvidiasett.enable = lib.mkDefault true;
}
