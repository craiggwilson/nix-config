{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.monitors;
in
{
  options.hdwlinux.features.monitors = with types; {
    enable = mkBoolOpt false "Whether or not to enable monitors.";
    monitors = mkOption {
      default = [ ];
      description = "Monitors and their wallpaper.";
      type = listOf (submodule {
        options = {
          name = mkOption { type = str; };
          width = mkOption { type = int; };
          height = mkOption { type = int; };
          x = mkOption { type = int; };
          y = mkOption { type = int; };
          scale = mkOption { type = int; };
          wallpaper = mkOption { type = path; };
          workspace = mkOption { type = str; };
        };
      });
    };
  };
}
