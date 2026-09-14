{
  config.substrate.modules.networking.tailscale = {
    tags = [
      "networking:tailscale"
      "users:craig:personal"
    ];

    nixos = {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };
    };
  };
}
