{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.services.osquery;
in
{
  options.hdwlinux.services.osquery = {
    enable = config.lib.hdwlinux.mkEnableOption "osquery" "work";
  };

  config = lib.mkIf cfg.enable {
    services.osquery.enable = true;
  };
}
