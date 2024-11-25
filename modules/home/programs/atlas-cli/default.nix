{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.atlas-cli;
in
{
  options.hdwlinux.programs.atlas-cli = {
    enable = config.lib.hdwlinux.mkEnableAllOption "atlas-cli" [
      "programming"
      "work"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.hdwlinux.atlas-cli ];
  };
}
