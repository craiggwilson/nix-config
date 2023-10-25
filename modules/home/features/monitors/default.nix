{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.monitors;
in
{
  options.hdwlinux.features.monitors = with types; {
    monitors = mkOption {
      description = "Options to set the monitor configuration.";
      type = listOf (submodule {
        options = {
          name = mkOption { type = str; };
          width = mkOption { type = int; };
          height = mkOption { type = int; };
          x = mkOption { type = int; };
          y = mkOption { type = int; };
          scale = mkOption { type = int; };
          workspace = mkOption { type = str; };
        };
      });
    };
  };
}
