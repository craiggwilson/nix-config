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
    enable = lib.mkOption {
      description = "Whether to enable tailscale.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "networking:tailscale" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    networking.firewall.checkReversePath = "loose";
  };
}
