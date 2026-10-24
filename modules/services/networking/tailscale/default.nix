{
  config.substrate.modules.services.networking.tailscale = {
    tags = [
      "core:networking:tailscale"
    ];

    nixos = {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };
    };
  };
}
