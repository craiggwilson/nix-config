{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.bluetooth;
in
{
  options.hdwlinux.features.bluetooth = {
    enable = mkEnableOpt [ "bluetooth" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
