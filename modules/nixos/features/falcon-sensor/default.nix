{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hdwlinux.features.falcon-sensor;
  falcon = pkgs.hdwlinux.falcon-sensor;
in
{
  options.hdwlinux.features.falcon-sensor = {
    enable = lib.hdwlinux.mkEnableOpt [ "work" ] config.hdwlinux.features.tags;
    cid = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = [
      falcon.pkgs.falconctl
      falcon.pkgs.falcon-kernel-check
    ];

    systemd.services.falcon-sensor = {
      enable = true;
      description = "CrowdStrike Falcon Sensor";
      unitConfig.DefaultDependencies = false;
      after = [ "local-fs.target" ];
      conflicts = [ "shutdown.target" ];
      before = [
        "sysinit.target"
        "shutdown.target"
      ];
      serviceConfig = {
        ExecStartPre =
          (pkgs.writeShellScriptBin "init-falcon" ''
            mkdir -p /opt/CrowdStrike
            ln -sf ${falcon}/opt/CrowdStrike/* /opt/CrowdStrike
            ${falcon.pkgs.falconctl}/bin/falconctl -f -s --cid=${cfg.cid}
          '')
          + "/bin/init-falcon";
        ExecStart = "${falcon.pkgs.falcond}/bin/falcond";
        Type = "forking";
        PIDFile = "/run/falcond.pid";
        Restart = "no";
        TimeoutStopSec = "60s";
        KillMode = "process";
      };
      wantedBy = [ "multi-user.target" ];
    };

    boot = {
      kernelPackages = pkgs.linuxPackages_6_6;
      kernelPatches = [
        {
          name = "crowdstrike";
          patch = null;
          extraConfig = ''
            DEBUG_INFO_BTF y
          '';
        }
      ];
    };
  };
}
