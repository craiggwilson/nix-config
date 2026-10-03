{
  config.substrate.modules.services.falcon-sensor = {
    tags = [ "users:craig:work" ];

    nixos =
      {
        config,
        pkgs,
        wrap,
        ...
      }:
      let
        falcon = pkgs.hdwlinux.falcon-sensor;
        initFalcon = wrap.package {
          package = pkgs.writeShellApplication {
            name = "init-falcon";
            text = ''
              mkdir -p /opt/CrowdStrike
              ln -sf ${falcon}/opt/CrowdStrike/* /opt/CrowdStrike
              ${falcon.pkgs.falconctl}/bin/falconctl -f -s --cid="$FALCON_CID"
            '';
          };
        };
      in
      {
        secretspec = {
          entries.FALCON_CID = {
            description = "CrowdStrike Falcon sensor customer ID used to register the host.";
            ref = {
              vault = "Work";
              item = "falcon-sensor";
              field = "cid";
            };
          };
          scopes.falcon.secrets = [ "FALCON_CID" ];
        };

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
            ExecStartPre = "${
              wrap.package {
                package = initFalcon;
                secrets.scope = "falcon";
              }
            }/bin/init-falcon";
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
