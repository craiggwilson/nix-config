{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.lshw;
in
{
  options.hdwlinux.programs.lshw = {
    enable = lib.hdwlinux.mkEnableOption "lshw" true;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.lshw ];
  };
}
