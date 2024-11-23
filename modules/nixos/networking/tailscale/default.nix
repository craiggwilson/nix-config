{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.networking.tailscale;
in
{
  options.hdwlinux.networking.tailscale = {
    enable = config.lib.hdwlinux.features.mkEnableOption "tailscale" "networking:tailscale";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    networking.firewall.checkReversePath = "loose";
  };
}
