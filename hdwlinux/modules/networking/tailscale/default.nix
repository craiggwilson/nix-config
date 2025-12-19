{
  config.substrate.modules.networking.tailscale = {
    tags = [ "networking:tailscale" ];

    nixos =
      { lib, ... }:
      {
        options.hdwlinux.networking.tailscale.tailnet = lib.mkOption {
          description = "The tailnet domain (e.g., tailc675f.ts.net).";
          type = lib.types.str;
          default = "tailc675f.ts.net";
        };

        config = {
          services.tailscale = {
            enable = true;
            useRoutingFeatures = "client";
          };
        };
      };

    homeManager =
      { lib, ... }:
      {
        options.hdwlinux.networking.tailscale.tailnet = lib.mkOption {
          description = "The tailnet domain (e.g., tailc675f.ts.net).";
          type = lib.types.str;
          default = "tailc675f.ts.net";
        };
      };
  };
}
