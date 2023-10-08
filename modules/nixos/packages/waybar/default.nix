{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.waybar;
in
{
  options.hdwlinux.packages.waybar = with types; {
    enable = mkBoolOpt false "Whether or not to enable waybar.";
    settings = mkOpt attrs { } (mdDoc "Options to pass directly to `programs.waybar.settings`.");
    style = mkOpt (nullOr (either path lines)) null (mdDoc "Options to pass directly to `programs.waybar.style`.");
  };

  config = mkIf cfg.enable {
    hdwlinux.home.programs.waybar = {
      enable = true;
      settings = mkAliasDefinitions options.hdwlinux.packages.waybar.settings;
      style = mkAliasDefinitions options.hdwlinux.packages.waybar.style;
    };
  };
}
