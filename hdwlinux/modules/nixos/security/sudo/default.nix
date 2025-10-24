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
    enablePasswordlessSudo = config.lib.hdwlinux.mkEnableOption "sudo" "personal";
  };

  config = {
    security.sudo.execWheelOnly = true;
    security.sudo.wheelNeedsPassword = !cfg.enablePasswordlessSudo;
  };
}
