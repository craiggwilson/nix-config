{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.features.yazi;
in
{
  options.hdwlinux.features.yazi = {
    enable = lib.hdwlinux.mkEnableOpt [ "cli" ] config.hdwlinux.features.tags;
  };

  config.programs.yazi = lib.mkIf cfg.enable {
    enable = true;
  };
}
