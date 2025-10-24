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
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
  };
}
