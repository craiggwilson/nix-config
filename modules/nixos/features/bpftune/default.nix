{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.features.bpftune;
in
{
  options.hdwlinux.features.bpftune = {
    enable = lib.hdwlinux.mkEnableOpt [ "bpftune" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    services.bpftune.enable = true;
  };
}
