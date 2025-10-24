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
    enable = config.lib.hdwlinux.mkEnableOption "evergreen" [
      "programming"
      "work"
    ];
    configFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.evergreen.yml";
      description = "Path to the Evergreen configuration file.";
    };
  };

  config = lib.mkIf (cfg.enable) {
    home.packages = [
      (pkgs.writeScriptBin "evergreen" ''
        ${pkgs.hdwlinux.evergreen}/bin/evergreen --config "${cfg.configFile}" "$@"
      '')
    ];
  };
}
