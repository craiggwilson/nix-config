{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.gnome-keyring;
in
{
  options.hdwlinux.features.gnome-keyring = with types; {
    enable = mkEnableOpt ["desktop:hyprland"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {

    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" "ssh" ];
    };

    home.packages = with pkgs; [
      libsecret
    ];
  };
}
