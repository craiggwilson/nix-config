{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.services.tailscale;
in
{
  options.hdwlinux.services.tailscale = {
    enable = lib.mkEnableOption "tailscale";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    networking.firewall.checkReversePath = "loose";
  };
}
