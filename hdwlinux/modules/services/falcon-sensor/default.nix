{
  config.substrate.modules.services.falcon-sensor = {
    tags = [ "users:craig:work" ];

    nixos =
      {
        config,
        pkgs,
        ...
      }:
      let
        falcon = pkgs.hdwlinux.falcon-sensor;
      in
      {
        hdwlinux.security.secrets.entries.falconSensor = {
          reference = "op://Work/falcon-sensor/cid";
          mode = "0600";
        };

        environment.systemPackages = [
          falcon.pkgs.falconctl
          falcon.pkgs.falcon-kernel-check
        ];

        systemd.services.falcon-sensor = {
          enable = true;
          description = "CrowdStrike Falcon Sensor";
          unitConfig.DefaultDependencies = false;
          after = [
            "local-fs.target"
          ];
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
                ${falcon.pkgs.falconctl}/bin/falconctl -f -s --cid=$(cat ${config.hdwlinux.security.secrets.entries.falconSensor.path})
              '')
              + "/bin/init-falcon";
            ExecStart = "${falcon.pkgs.falcond}/bin/falcond";
            Type = "forking";
            PIDFile = "/run/falcond.pid";
            Restart = "always";
            TimeoutStopSec = "60s";
            KillMode = "process";
          };
          wantedBy = [ "multi-user.target" ];
        };
      };
  };
}
