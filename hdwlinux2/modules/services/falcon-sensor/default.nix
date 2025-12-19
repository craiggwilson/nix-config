{
  config.substrate.modules.services.falcon-sensor = {
    tags = [ "users:craig:work" ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        falcon = pkgs.hdwlinux.falcon-sensor;
      in
      let
        cfg = config.hdwlinux.services.falcon-sensor;
      in
      {
        options.hdwlinux.services.falcon-sensor = {
          cidFile = lib.mkOption {
            type = lib.types.str;
            description = "Path to file containing the CrowdStrike CID.";
          };
        };

        config = {
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
                  ${falcon.pkgs.falconctl}/bin/falconctl -f -s --cid=$(cat ${cfg.cidFile})
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
  };
}
