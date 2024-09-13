{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.evergreen;
in
{
  options.hdwlinux.features.evergreen = {
    enable = lib.hdwlinux.mkEnableOpt [
      "cli"
      "programming"
      "work"
    ] config.hdwlinux.features.tags;
    extraConfig = lib.hdwlinux.mkStrOpt null "Extra configuration for evergreen.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.hdwlinux.evergreen ];
    home.file.".evergreen.yml".text = lib.mkIf cfg.extraConfig != null cfg.extraConfig;
  };
}
