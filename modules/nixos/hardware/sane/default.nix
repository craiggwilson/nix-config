{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.hardware.sane;
in
{
  options.hdwlinux.hardware.sane = {
    enable = config.lib.hdwlinux.mkEnableOption "sane" "scanning";
  };

  config = lib.mkIf cfg.enable {
    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
    };
  };
}
