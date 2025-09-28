{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.programs.mcp-nixos;
in
{
  options.hdwlinux.programs.mcp-nixos = {
    enable = config.lib.hdwlinux.mkEnableOption "mcp-nixos" [
      "programming"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.mcp-nixos ];
  };
}
