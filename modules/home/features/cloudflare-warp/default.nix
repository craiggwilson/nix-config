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
    systemd.user.services.warp-svc = {
      Unit = {
        Description = "Cloudflare Zero Trust Client Taskbar";
        Documentation = ["https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/"];
        After = ["dbus.socket"];
        BindsTo= ["graphical-session.target"];
        Requires = ["dbus.socket"];
      };
      Install = {
        WantedBy = ["default.target"];
      };
      Service = {
          Type = "simple";
          ExecStart = "${pkgs.cloudflare-warp}/bin/warp-taskbar";
          Restart = "always";
      };
    };
  };
}
