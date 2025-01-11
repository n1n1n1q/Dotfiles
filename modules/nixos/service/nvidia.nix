{ lib, config, ... }:

{
  options = {
    nvidiasett.enable = lib.mkEnableOption "Enable nvidia settings";
    default = true;
  };

  config = lib.mkIf config.nvidiasett.enable {
    hardware = {
      graphics.enable = true;
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;
      # powerManagement.enable = true;
      # powerManagement.finegrained = true;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
