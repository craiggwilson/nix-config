{ config, lib, pkgs, ... }:

let cfg = config.hdwlinux.features.gnome-keyring;
in
{
  options.hdwlinux.features.gnome-keyring = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {

    services.gnome.gnome-keyring = {
      enable = true;
    };

    environment.systemPackages = [
      pkgs.libsecret
    ];
  };
}
