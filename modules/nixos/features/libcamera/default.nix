{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.libcamera;
in
{
  options.hdwlinux.features.libcamera = with types; {
    enable = mkEnableOpt ["camera"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ 
        libcamera
    ];
  };
}
