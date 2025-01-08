{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.security.sudo;
in
{
  options.hdwlinux.security.sudo = {
    enable = config.lib.hdwlinux.mkEnableOption "sudo" "personal";
  };

  config = lib.mkIf cfg.enable {
    security.sudo.wheelNeedsPassword = false;
  };
}
