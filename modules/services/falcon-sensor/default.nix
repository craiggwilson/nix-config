{
  config.substrate.modules.services.falcon-sensor = {
    tags = [
      "user:craig"
      "profile:work"
    ];

    nixos =
      {
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
              # The deb ships empty ASPM/Falcon4IT/Packages directories, and the
              # sensor also creates real ones there at runtime; `ln` cannot replace
              # a directory with a symlink, so leave existing directories alone and
              # only refresh files and stale links.
              for entry in ${falcon}/opt/CrowdStrike/*; do
                name=$(basename "$entry")
                if [[ -e "/opt/CrowdStrike/$name" && ! -L "/opt/CrowdStrike/$name" ]]; then
                  continue
                fi
                ln -sfn "$entry" "/opt/CrowdStrike/$name"
              done
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
          # init-falcon fetches the CID from 1Password on every start, so the
          # unit cannot run before the network exists. The deb package's
          # pre-sysinit ordering (DefaultDependencies=false, before
          # sysinit.target) races DNS at boot, burns the start limit in one
          # second, and leaves the sensor dead; standard dependencies plus
          # network-online start it a few seconds later but actually running.
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
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
            # WARP's DNS proxy connects after network-online, so the first
            # attempts can still fail; space retries out so they ride past
            # the default start limit instead of tripping it.
            RestartSec = 15;
            TimeoutStopSec = "60s";
            # falcond forks the real sensor into its own cgroup; with the
            # default KillMode=process a stop kills only falcond and orphans
            # the sensor, which then holds the kernel sensor resources and
            # makes every subsequent start fail with EBUSY.
            KillMode = "control-group";
          };
          wantedBy = [ "multi-user.target" ];
        };
      };
  };
}
