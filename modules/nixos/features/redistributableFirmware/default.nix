{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
let
  cfg = config.hdwlinux.features.redistributableFirmware;
in
{

  options.hdwlinux.features.redistributableFirmware = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable { hardware.enableRedistributableFirmware = true; };
}
