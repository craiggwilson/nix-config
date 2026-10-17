{
  config.substrate.modules.locations.raeford.ssh = {
    provides = [
      "locations:raeford:ssh"
      "core:ssh"
    ];
    requires = [
      "location:raeford"
      "users:craig"
    ];
    homeManager =
      {
        config,
        hasCapability,
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
        hdwlinux.security.ssh.settings =
          lib.genAttrs (lib.filter (m: !(hasCapability "host:${m}")) machines)
            (m: {
              HostName = "${m}.${domain}";
              User = config.home.username;
            });
      };
  };
}
