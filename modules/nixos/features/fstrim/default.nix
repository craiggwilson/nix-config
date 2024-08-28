{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.features.fstrim;
in
{
  options.hdwlinux.features.fstrim = {
    enable = lib.hdwlinux.mkBoolOpt true "Enable fstrim feature.";
  };

  config = lib.mkIf cfg.enable {
    services.fstrim.enable = true;
  };
}
