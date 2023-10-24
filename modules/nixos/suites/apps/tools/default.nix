{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.suites.apps.tools;
in
{
  options.hdwlinux.suites.apps.tools = with types; {
    enable = mkBoolOpt false "Whether or not to enable the tools apps.";
  };

  config = mkIf cfg.enable {
    hdwlinux.features = {
      dconf.enable = true;
      lshw.enable = true;
      pciutils.enable = true;
      podman.enable = true;
      usbutils.enable = true;
    };
  };
}
