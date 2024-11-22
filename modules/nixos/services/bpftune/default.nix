{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.services.bpftune;
in
{
  options.hdwlinux.services.bpftune = {
    enable = lib.mkOption {
      description = "Whether to enable bpftune.";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.bpftune.enable = true;
  };
}
