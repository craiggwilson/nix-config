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
    enable = lib.hdwlinux.mkBoolOpt true "Whether to enable bpftune.";
  };

  config = lib.mkIf cfg.enable {
    services.bpftune.enable = true;
  };
}
