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
  options.hdwlinux.programs.zip = {
    enable = lib.hdwlinux.mkEnableOption "unzip" true;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.unzip ];
  };
}
