{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.libcamera;
in
{
  options.hdwlinux.packages.libcamera = with types; {
    enable = mkBoolOpt false "Whether or not to enable libcamera.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ 
        libcamera
    ];
  };
}
