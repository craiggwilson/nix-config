{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.security.polkit;
in
{
  options.hdwlinux.security.polkit = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    security.polkit.enable = true;
  };
}
