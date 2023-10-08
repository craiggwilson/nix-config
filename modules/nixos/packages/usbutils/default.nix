{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.usbutils;
in
{
  options.hdwlinux.packages.usbutils = with types; {
    enable = mkBoolOpt false "Whether or not to enable pciutils.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        usbutils
    ];
  };
}
