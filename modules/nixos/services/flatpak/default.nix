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
    enable = lib.hdwlinux.mkEnableTagsOpt "flatpak" [ "gui" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
  };
}
