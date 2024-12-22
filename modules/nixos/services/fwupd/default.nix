{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.services.fwupd;
in
{
  options.hdwlinux.services.fwupd = {
    enable = lib.hdwlinux.mkEnableOption "fwupd" true;
  };

  config = lib.mkIf cfg.enable {
    services.fwupd = {
      enable = true;
    };
  };
}
