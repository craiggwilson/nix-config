{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.obsidian;
in
{
  options.hdwlinux.programs.obsidian = {
    enable = config.lib.hdwlinux.mkEnableOption "obsidian" "gui";
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (!config.hdwlinux.services.flatpak.enable) [ pkgs.obsidian ];

    hdwlinux.services.flatpak.packages = lib.mkIf config.hdwlinux.services.flatpak.enable [
      "md.obsidian.Obsidian"
    ];
  };
}
