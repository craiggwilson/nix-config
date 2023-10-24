{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.usbutils;
in
{
  options.hdwlinux.features.usbutils = with types; {
    enable = mkBoolOpt false "Whether or not to enable pciutils.";
  };

  config.environment.systemPackages = with pkgs; mkIf cfg.enable [
    usbutils
  ];
}
