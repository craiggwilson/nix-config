{ options, config, lib, pkgs, ... }:

with lib;
with lib.hdwlinux;
let cfg = config.hdwlinux.features.cloudflare-warp;
in
{
  options.hdwlinux.features.cloudflare-warp = with types; {
    enable = mkEnableOpt ["work"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cloudflare-warp
    ];

    systemd.services.warp-svc = {
      description = "Cloudflare Zero Trust Client Daemon";
      documentation = ["https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/"];
      after = ["pre-network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.cloudflare-warp}/bin/warp-svc";
          DynamicUser = "no";
          CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
          AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE";
          StateDirectory = "cloudflare-warp";
          RuntimeDirectory = "cloudflare-warp";
          LogsDirectory = "cloudflare-warp";
          Restart = "always";
      };
    };
  };
}
