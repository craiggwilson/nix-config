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
  cfg = config.hdwlinux.features.structurizr-lite;
in
{
  options.hdwlinux.features.structurizr-lite = with types; {
    enable = mkEnableOpt [
      "gui"
      "programming"
      "work"
    ] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [ hdwlinux.structurizr-lite ];
}
