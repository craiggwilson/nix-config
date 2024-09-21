{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.wayvnc;
in
{
  options.hdwlinux.features.wayvnc = {
    enable = lib.hdwlinux.mkEnableOpt [ "vnc" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.wayvnc
    ];

    networking.firewall.allowedTCPPorts = [ 5900 ];
  };
}
