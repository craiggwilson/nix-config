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
    enable = lib.mkOption {
      description = "Whether to enable osquery.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "work" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
    services.osquery.enable = true;
  };
}
