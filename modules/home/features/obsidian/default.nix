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
  cfg = config.hdwlinux.features.obsidian;
in
{
  options.hdwlinux.features.obsidian = with types; {
    enable = mkEnableOpt [ "gui" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; mkIf (!config.hdwlinux.features.flatpak.enable) [ obsidian ];

    services.flatpak.packages = mkIf config.hdwlinux.features.flatpak.enable [ "md.obsidian.Obsidian" ];
  };
}
