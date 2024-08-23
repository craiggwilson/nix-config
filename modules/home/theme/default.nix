{
  lib,
  pkgs,
  inputs,
  config,
  options,
  ...
}:
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.theme;
in
{
  options.hdwlinux.theme = with types; {
    enable = mkBoolOpt false "Whether to enable theming.";
    name = mkStrOpt "" "The name of the theme.";
    colors = mkOpt attrs { } "The current colors.";
    dark = mkBoolOpt true "Whether the theme is dark.";

    wallpapers = mkOption {
      description = "The wallpapers for the system.";
      type = listOf path;
    };
  };
}
