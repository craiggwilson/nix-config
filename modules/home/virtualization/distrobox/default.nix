{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.virtualization.distrobox;
in
{
  options.hdwlinux.virtualization.distrobox = {
    enable = config.lib.hdwlinux.mkEnableOption "distrobox" [
      "work"
      "programming"
    ];
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.distrobox ];
  };
}
