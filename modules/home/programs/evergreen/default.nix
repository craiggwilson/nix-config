{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.evergreen;
in
{
  options.hdwlinux.programs.evergreen = {
    enable = config.lib.hdwlinux.mkEnableAllOption "evergreen" [
      "programming"
      "work"
    ];
    extraConfig = lib.mkOption {
      description = "Extra configuration for evergreen.";
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.hdwlinux.evergreen ];
    home.file.".evergreen.yml".text = lib.mkIf (cfg.extraConfig != null) cfg.extraConfig;
  };
}
