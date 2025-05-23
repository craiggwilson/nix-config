{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.services.cloudflare-warp;
in
{
  options.hdwlinux.services.cloudflare-warp = {
    enable = config.lib.hdwlinux.mkEnableOption "cloudflare-warp" "work";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ cloudflare-warp ];

    systemd.services.cloudflare-warp = {
      description = "Cloudflare Zero Trust Client Daemon";
      documentation = [
        "https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/"
      ];
      after = [ "pre-network.target" ];
      wantedBy = [ "multi-user.target" ];
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
