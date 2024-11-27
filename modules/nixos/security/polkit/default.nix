{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.security.polkit;
in
{
  options.hdwlinux.security.polkit = {
    enable = lib.hdwlinux.mkEnableOption "polkit" true;
  };

  config = lib.mkIf cfg.enable {
    security.polkit.enable = true;
  };
}
