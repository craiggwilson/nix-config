{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.flatpak;
in
{
  options.hdwlinux.features.flatpak = with types; {
    enable = mkEnableOpt ["flatpak"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    services.flatpak.enable = true;

    system.activationScripts = {
      flathub = ''
        /run/current-system/sw/bin/flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };
}
