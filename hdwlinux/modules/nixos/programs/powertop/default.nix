{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.powertop;
in
{
  options.hdwlinux.programs.powertop = {
    enable = lib.hdwlinux.mkEnableOption "powertop" true;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.powertop ];
  };
}
