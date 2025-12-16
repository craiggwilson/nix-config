{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.services.gnome-keyring;
in
{
  options.hdwlinux.services.gnome-keyring = {
    enable = config.lib.hdwlinux.mkEnableOption "gnome-keyring" "gui";
  };

  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring = {
      enable = true;
    };

    environment.systemPackages = [ pkgs.libsecret ];
  };
}
