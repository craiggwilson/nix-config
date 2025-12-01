{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.services.system76-scheduler;
in
{
  options.hdwlinux.services.system76-scheduler = {
    enable = lib.hdwlinux.mkEnableOption "system76-scheduler" true;
  };

  config = lib.mkIf cfg.enable {
    services.system76-scheduler = {
      enable = true;
    };
  };
}
