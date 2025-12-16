{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.services.bpftune;
in
{
  options.hdwlinux.services.bpftune = {
    enable = lib.hdwlinux.mkEnableOption "bpftune" true;
  };

  config = lib.mkIf cfg.enable {
    services.bpftune.enable = true;
  };
}
