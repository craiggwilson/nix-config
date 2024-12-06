{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.ags;
in
{
  options.hdwlinux.desktopManagers.hyprland.ags = {
    enable = lib.hdwlinux.mkEnableOption "ags" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    programs.ags = {
      enable = true;
      configDir = ./src;
      extraPackages = builtins.attrValues (
        builtins.removeAttrs inputs.astal.packages.${pkgs.system} [
          "cava"
          "docs"
        ]
      );
    };
  };
}
