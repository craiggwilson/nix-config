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
    tailnet = lib.hdwlinux.sharedOptions.networking.tailscale.tailnet;
  };

  config = lib.mkIf cfg.enable {

    hdwlinux.networking.tailscale.tailnet = lib.mkDefault "tailc675f.ts.net";

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
