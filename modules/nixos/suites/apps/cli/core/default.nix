{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.cli.core;
in
{
  options.hdwlinux.suites.apps.cli.core = with types; {
    enable = mkBoolOpt false "Whether or not to enable the command line apps.";
  };

  config.hdwlinux.features = mkIf cfg.enable {
    _1password-cli.enable = true;
    lshw.enable = true;
    neofetch.enable = true;
    nvtop.enable = true;
    pciutils.enable = true;
    podman.enable = true;
    procps.enable = true;
    usbutils.enable = true;
  };
}
