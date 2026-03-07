{
  config.substrate.modules.networking.tailscale = {
    tags = [ "networking:tailscale" ];

    nixos = {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };
    };
  };
}
