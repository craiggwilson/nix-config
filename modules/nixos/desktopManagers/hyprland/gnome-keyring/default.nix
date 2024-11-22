{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.gnome-keyring;
in
{
  options.hdwlinux.desktopManagers.hyprland.gnome-keyring = {
    enable = lib.mkOption {
      description = "Whether to enable gnome-keyring.";
      type = lib.types.bool;
      default = config.hdwlinux.desktopManagers.hyprland.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring = {
      enable = true;
    };

    environment.systemPackages = [ pkgs.libsecret ];
  };
}
