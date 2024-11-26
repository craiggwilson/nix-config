{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.ryujinx;
in
{
  options.hdwlinux.programs.ryujinx = {
    enable = config.lib.hdwlinux.mkEnableOption "ryujinx" [
      "gaming"
      "gui"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.ryujinx ];
  };
}
