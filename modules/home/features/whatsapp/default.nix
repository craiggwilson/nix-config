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
  cfg = config.hdwlinux.features.whatsapp;
in
{
  options.hdwlinux.features.whatsapp = with types; {
    enable = mkEnableOpt [
      "gui"
    ] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [ whatsapp-for-linux ];
}
