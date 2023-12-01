{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.swaylock;
in
{
  options.hdwlinux.features.swaylock = with types; {
    enable = mkEnableOpt ["desktop:hyprland"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    programs.swaylock = {
      enable = true;
      settings = {
        ignore-empty-password = false;
        line-uses-ring = true;
        indicator-radius = 100;
        indicator-thickness = 10;
      };
    };

    hdwlinux.theme.targets.swaylock.enable = true;
  };
}
