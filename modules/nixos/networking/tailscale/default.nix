{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.networking.tailscale;
in
{
  options.hdwlinux.networking.tailscale = {
    enable = config.lib.hdwlinux.mkEnableOption "tailscale" "networking:tailscale";
    tailnet = lib.mkOption {
      type = lib.types.str;
      default = "tailc675f.ts.net";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    home-manager.sharedModules = [
      {
        hdwlinux.networking.tailscale.tailnet = cfg.tailnet;
      }
    ];
  };
}
