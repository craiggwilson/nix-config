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
    enable = lib.mkOption {
      description = "Whether to enable flatpak.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "gui" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
  };
}
