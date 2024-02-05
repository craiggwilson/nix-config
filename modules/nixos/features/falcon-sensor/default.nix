{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let 
    cfg = config.hdwlinux.features.falcon-sensor;
    falcon = "${pkgs.hdwlinux.falcon-sensor}";
in
{
  options.hdwlinux.features.falcon-sensor = with types; {
    enable = mkEnableOpt ["work"] config.hdwlinux.features.tags;
    cid = mkOption { type = str; };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.falcon-sensor = {
      enable = true;
      description = "CrowdStrike Falcon Sensor";
      unitConfig.DefaultDependencies = false;
      after = [ "local-fs.target" ];
      conflicts = [ "shutdown.target" ];
      before = [ "sysinit.target" "shutdown.target" ];
      serviceConfig = {
        ExecStartPre = (pkgs.writeShellScriptBin "init-falcon" ''
          mkdir -p /opt/CrowdStrike
          ln -sf ${falcon}/opt/CrowdStrike/* /opt/CrowdStrike
          ${falcon}/bin/fs-bash -c "${falcon}/opt/CrowdStrike/falconctl -f -s --cid=${cfg.cid}"
        '') + "/bin/init-falcon";
        ExecStart = "${falcon}/bin/fs-bash -c \"${falcon}/opt/CrowdStrike/falcond\"";
        Type = "forking";
        PIDFile = "/run/falcond.pid";
        Restart = "no";
        TimeoutStopSec = "60s";
        KillMode = "process";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
