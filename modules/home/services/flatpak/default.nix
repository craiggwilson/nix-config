{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.services.flatpak;
in
{
  options.hdwlinux.services.flatpak = {
    enable = config.lib.hdwlinux.mkEnableOption "flatpak" "gui";
    packages = lib.mkOption {
      description = "The flatpacks to install.";
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.systemDirs.data = [ "${config.xdg.dataHome}/flatpak/exports/share" ];

    services.flatpak = {
      remotes = [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
      ];
      packages = [ "com.github.tchx84.Flatseal" ] ++ cfg.packages;
      update.auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };
  };
}
