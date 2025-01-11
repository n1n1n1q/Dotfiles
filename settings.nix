{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.settings;
in
{
  options.settings = {
    username = mkOption {
      type = types.str;
      default = "oleh";
    };
    homedir = mkOption {
      type = types.str;
      default = "/home/oleh";
    };

  };

  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module
  # by setting "services.hello.enable = true;".
  # config = mkIf cfg.enable {
  #   systemd.services.hello = {
  #     wantedBy = [ "multi-user.target" ];
  #     serviceConfig.ExecStart = "${pkgs.hello}/bin/hello -g'Hello, ${escapeShellArg cfg.greeter}!'";
  #   };
  # };
}
