{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.pciutils;
in
{
  options.hdwlinux.programs.pciutils = {
    enable = lib.hdwlinux.mkEnableOption "pciutils" true;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.pciutils ];
  };
}
