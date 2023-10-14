{ lib, pkgs, inputs, config, options, ... }: 
with lib;
with lib.hdwlinux;
{
  options.hdwlinux.theme = with types; {
    color0 = mkStrOpt "" "The base color.";
    color1 = mkStrOpt "" "The next color.";
    color2 = mkStrOpt "" "The next color.";
    color3 = mkStrOpt "" "The next color.";
    color4 = mkStrOpt "" "The next color.";
    color5 = mkStrOpt "" "The next color.";
    color6 = mkStrOpt "" "The next color.";
    color7 = mkStrOpt "" "The next color.";
    color8 = mkStrOpt "" "The next color.";
    color9 = mkStrOpt "" "The next color.";
    color10 = mkStrOpt "" "The next color.";
    color11 = mkStrOpt "" "The next color.";
    color12 = mkStrOpt "" "The next color.";
    color13 = mkStrOpt "" "The next color.";
    color14 = mkStrOpt "" "The next color.";
    color15 = mkStrOpt "" "The next color.";

    wallpaper1 = mkOpt (nullOr path) null "Wallpaper for monitor 1.";
    wallpaper2 = mkOpt (nullOr path) null "Wallpaper for monitor 2.";
    wallpaper3 = mkOpt (nullOr path) null "Wallpaper for monitor 3.";
  };
}
