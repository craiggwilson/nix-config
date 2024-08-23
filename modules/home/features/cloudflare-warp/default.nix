{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.cloudflare-warp;
in
{
  options.hdwlinux.features.cloudflare-warp = {
    enable = lib.hdwlinux.mkEnableOpt [ "work" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    # systemd.user.services.warp-taskbar = {
    #   Unit = {
    #     Description = "Cloudflare Zero Trust Client Taskbar";
    #     Documentation = [ "https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/" ];
    #     After = [ "graphical-session-pre.target" ];
    #     PartOf = [ "graphical-session.target" ];
    #   };
    #   Install = {
    #     WantedBy = [ "graphical-session.target" ];
    #   };
    #   Service = {
    #     Type = "simple";
    #     ExecStart = "${pkgs.cloudflare-warp}/bin/warp-taskbar";
    #     Restart = "always";
    #   };
    # };
  };
}
