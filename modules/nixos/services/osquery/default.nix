{
  config,
  lib,
  ...
}:

let
  tags = config.hdwlinux.features.tags;
  cfg = config.hdwlinux.services.osquery;
in
{
  options.hdwlinux.services.osquery = {
    enable = lib.hdwlinux.mkEnableTagsOpt "osquery" [ "work" ] tags;
  };

  config = lib.mkIf cfg.enable {
    services.osquery.enable = true;
  };
}
