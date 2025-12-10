{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.programs.home-manager;
in
{
  options.hdwlinux.programs.home-manager = {
    enable = lib.hdwlinux.mkEnableOption "home-manager" true;
  };

  config = {
    programs.home-manager.enable = cfg.enable;
  };
}
