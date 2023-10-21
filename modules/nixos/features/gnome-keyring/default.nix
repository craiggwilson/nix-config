{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.gnome-keyring;
in
{
  options.hdwlinux.features.gnome-keyring = with types; {
    enable = mkBoolOpt false "Whether or not to enable gnome-keyring.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.services.gnome-keyring = {
      enable = true;
      components = [ "secrets" "ssh" ];
    };
  };
}
