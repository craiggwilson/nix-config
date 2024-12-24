{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.home-manager;
in
{
  options.hdwlinux.home-manager = {
    enable = lib.hdwlinux.mkEnableOption "home-manager" true;
  };

  config = {
    programs.home-manager.enable = cfg.enable;
  };
}
