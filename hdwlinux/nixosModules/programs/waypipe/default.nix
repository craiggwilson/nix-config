{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.waypipe;
in
{
  options.hdwlinux.programs.waypipe = {
    enable = lib.hdwlinux.mkEnableOption "usbutils" false;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.waypipe
      pkgs.xorg.xauth
    ];
  };
}
