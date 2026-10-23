{
  config.substrate.modules.locations.raeford.ssh = {
    tags = [
      "users:craig"
      "raeford"
    ];
    homeManager =
      {
        config,
        hasTag,
        lib,
        ...
      }:
      let
        domain = config.hdwlinux.networking.domain;
        # LAN machines/devices reachable as <name>.<domain>;
        # each host gets entries for all others, never itself.
        # Resolution is backed by locations.raeford.hosts (/etc/hosts).
        machines = [
          "blackflame"
          "synology"
          "unsouled"
        ];
      in
      {
        hdwlinux.security.ssh.settings = lib.genAttrs (lib.filter (m: !(hasTag "host:${m}")) machines) (m: {
          HostName = "${m}.${domain}";
          User = config.home.username;
        });
      };
  };
}
