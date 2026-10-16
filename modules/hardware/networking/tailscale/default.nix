{
  config.substrate.modules.hardware.networking.tailscale = {
    provides = [ "hardware:networking:tailscale" "networking:tailscale" ];
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
