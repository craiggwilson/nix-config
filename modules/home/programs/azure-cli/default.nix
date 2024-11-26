{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.azure-cli;
in
{
  options.hdwlinux.programs.azure-cli = {
    enable = config.lib.hdwlinux.mkEnableOption "azure-cli" [
      "programming"
      "work"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.azure-cli ];
  };
}
