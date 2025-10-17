{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.services.kolide;
in
{
  options.hdwlinux.services.kolide = {
    enable = config.lib.hdwlinux.mkEnableOption "kolide" [ "work" ];
  };

  config = lib.mkIf cfg.enable {
    services.kolide-launcher.enable = true;
  };
}
