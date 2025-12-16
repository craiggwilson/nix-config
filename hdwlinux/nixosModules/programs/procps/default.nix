{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.procps;
in
{
  options.hdwlinux.programs.procps = {
    enable = lib.hdwlinux.mkEnableOption "procps" true;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.procps ];
  };
}
