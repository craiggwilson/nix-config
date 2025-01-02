{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.slurp;
in
{
  options.hdwlinux.desktopManagers.hyprland.slurp = {
    enable = lib.hdwlinux.mkEnableOption "slurp" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.slurp ];
  };
}
