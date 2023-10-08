{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.packages.bluetooth; 
in
{
  options.hdwlinux.packages.bluetooth = {
    enable = mkBoolOpt false "Whether or not to enable support for extra bluetooth devices.";
  };

  config = mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}