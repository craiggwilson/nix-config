{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.packages.gnome-keyring;
in
{
  options.hdwlinux.packages.gnome-keyring = with types; {
    enable = mkBoolOpt false "Whether or not to enable gnome-keyring.";
  };

  config = mkIf cfg.enable {
    hdwlinux.home.packages = with pkgs; [ 
        gnome.gnome-keyring
    ];

    hdwlinux.home.services.gnome-keyring.enable = true;
  };
}
