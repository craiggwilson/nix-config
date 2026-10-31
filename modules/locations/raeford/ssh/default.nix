{
  config.substrate.modules.locations.raeford.ssh = {
    tags = [
      "location:raeford"
    ];
    homeManager =
      {
        config,
        host,
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
          "craiggwilson@synology"
          "unsouled"
        ];
        parseMachine = machine: {
          hostname = lib.last (lib.splitString "@" machine);
          user =
            if lib.hasInfix "@" machine then lib.head (lib.splitString "@" machine) else config.home.username;
        };
      in
      {
        hdwlinux.security.ssh.settings = lib.listToAttrs (
          map (machine: {
            name = machine.hostname;
            value = {
              HostName = "${machine.hostname}.${domain}";
              User = machine.user;
            };
          }) (lib.filter (machine: machine.hostname != host) (map parseMachine machines))
        );
      };
  };
}
