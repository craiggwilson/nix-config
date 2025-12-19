{
  config.substrate.modules.locations.raeford.ssh = {
    tags = [
      "raeford"
      "networking:tailscale"
    ];

    homeManager =
      { config, lib, ... }:
      {
        hdwlinux.security.ssh.matchBlocks = {
          raeford = {
            host = "*.${config.hdwlinux.networking.domain}";
            forwardX11 = true;
          };
          tailnet = lib.mkIf (config.hdwlinux.networking.tailscale.tailnet != "") {
            host = "*.${config.hdwlinux.networking.tailscale.tailnet}";
            forwardX11 = true;
          };
        };
      };
  };
}
