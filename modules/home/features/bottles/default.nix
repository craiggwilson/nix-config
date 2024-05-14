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
  cfg = config.hdwlinux.features.bottles;
in
{
  options.hdwlinux.features.bottles = with types; {
    enable = mkEnableOpt [
      "gaming"
      "gui"
    ] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [ bottles ];
}
