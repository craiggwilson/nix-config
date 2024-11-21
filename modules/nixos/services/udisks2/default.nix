{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.udisks2;
in
{
  options.hdwlinux.udisks2 = {
    enable = lib.hdwlinux.mkEnableTagsOpt "udisks2" [
      "desktop:hyprland"
    ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    services.udisks2.enable = true;
  };
}
