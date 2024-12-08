{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.services.sunshine;
in
{
  options.hdwlinux.services.sunshine = {
    enable = config.lib.hdwlinux.mkEnableOption "sunshine" "gaming";
  };

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
    };
  };
}
