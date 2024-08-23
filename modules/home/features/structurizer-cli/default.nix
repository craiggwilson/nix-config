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
  cfg = config.hdwlinux.features.structurizr-cli;
in
{
  options.hdwlinux.features.structurizr-cli = with types; {
    enable = mkEnableOpt [
      "cli"
      "programming"
      "work"
    ] config.hdwlinux.features.tags;
  };

  config.home.packages = with pkgs; mkIf cfg.enable [ hdwlinux.structurizr-cli ];
}
