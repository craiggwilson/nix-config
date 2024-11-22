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
    enable = lib.mkOption {
      description = "Whether to enable tailscale.";
      type = lib.types.bool;
      default = false;
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
