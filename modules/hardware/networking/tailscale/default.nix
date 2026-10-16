{
  config.substrate.modules.hardware.networking.tailscale = {
    provides = [ "networking:tailscale" ];
    tags = [
      "networking:tailscale"
    ];

    nixos = {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };
    };
  };
}
