{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.programs.gnome-firmware;
in
{
  options.hdwlinux.programs.gnome-firmware = {
    enable = config.lib.hdwlinux.mkEnableOption "gnome-firmware" "gui";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.gnome-firmware ];
  };
}
