{
  options,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.pavucontrol;
in
{
  options.hdwlinux.features.pavucontrol = with types; {
    enable = mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [ pavucontrol ];
}
