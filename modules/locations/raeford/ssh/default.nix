{
  config.substrate.modules.locations.raeford.ssh = {
    tags = [
      "users:craig"
      "raeford"
    ];
    perUser =
      {
        config,
        hasTag,
        lib,
        ...
      }:
      let
        domain = config.hdwlinux.networking.domain;
        # LAN machines/devices reachable as <name>.<domain>;
        # each host gets entries for all others, never itself
        machines = [
          "blackflame"
          "unsouled"
        ];
      in
      {
        hdwlinux.security.ssh.settings = lib.genAttrs (lib.filter (m: !(hasTag "host:${m}")) machines) (m: {
          HostName = "${m}.${domain}";
          User = config.hdwlinux.user.name;
        });
      };
  };
}
