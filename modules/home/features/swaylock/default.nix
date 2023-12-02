{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.swaylock;
  inside = config.hdwlinux.theme.colors.with0x.base01;
  outside = config.hdwlinux.theme.colors.with0x.base01;
  ring = config.hdwlinux.theme.colors.with0x.base05;
  text = config.hdwlinux.theme.colors.with0x.base05;
  positive = config.hdwlinux.theme.colors.with0x.base0B;
  negative = config.hdwlinux.theme.colors.with0x.base08;
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

        color = outside;
        scaling = "fill";
        inside-color = inside;
        inside-clear-color = inside;
        inside-caps-lock-color = inside;
        inside-ver-color = inside;
        inside-wrong-color = inside;
        key-hl-color = positive;
        layout-bg-color = inside;
        layout-border-color = ring;
        layout-text-color = text;
        line-uses-inside = true;
        ring-color = ring;
        ring-clear-color = negative;
        ring-caps-lock-color = ring;
        ring-ver-color = positive;
        ring-wrong-color = negative;
        separator-color = "00000000";
        text-color = text;
        text-clear-color = text;
        text-caps-lock-color = text;
        text-ver-color = text;
        text-wrong-color = text;
        image = "${builtins.elemAt config.hdwlinux.theme.wallpapers 0}";
      };
    };
  };
}
