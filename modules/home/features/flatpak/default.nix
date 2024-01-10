{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.flatpak;
in
{
  options.hdwlinux.features.flatpak = with types; {
    enable = mkEnableOpt ["gui"] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    xdg.systemDirs.data = [
      "${config.xdg.dataHome}/flatpak/exports/share"
    ];
    
    services.flatpak = {
      remotes = [
        { name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }
      ];
      packages = [
        "com.github.tchx84.Flatseal"
      ];
      update.auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };
  };
}
