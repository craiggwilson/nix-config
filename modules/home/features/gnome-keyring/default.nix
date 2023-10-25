{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.gnome-keyring;
in
{
  options.hdwlinux.features.gnome-keyring = with types; {
    enable = mkBoolOpt false "Whether or not to enable gnome-keyring.";
  };

  config.services.gnome-keyring = mkIf cfg.enable {
    enable = true;
    components = [ "secrets" "ssh" ];
  };
}
