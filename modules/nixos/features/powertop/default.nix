{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.powertop;
in
{
  options.hdwlinux.features.powertop = {
    enable = lib.hdwlinux.mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
  };

  config = {
    environment.systemPackages = lib.mkIf cfg.enable [ pkgs.powertop ];

    powerManagement.powertop.enable = true;
  };
}
