{
  config.substrate.modules.locations.raeford.hosts = {
    tags = [
      "location:raeford"
    ];

    nixos =
      { config, lib, ... }:
      let
        domain = config.hdwlinux.networking.domain;
        # name -> IPs, first = most-likely-alive interface. Clients try each
        # address in order, so a dead first IP costs a ~1s ARP timeout before
        # failover. Both short name and FQDN resolve via /etc/hosts, bypassing
        # WARP's DNS hijack on unsouled entirely.
        machines = {
          blackflame = [
            "192.168.10.52" # wifi
            "192.168.10.72" # ethernet
          ];
          unsouled = [
            "192.168.10.53" # ethernet
            "192.168.10.66" # wifi
          ];
          synology = [ "192.168.100.50" ];
          printer = [ "192.168.150.71" ];
        };
      in
      {
        # extraHosts (literal text) rather than networking.hosts (attrset),
        # which renders in IP-sorted order and would lose the failover ordering.
        networking.extraHosts = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            name: ips: lib.concatMapStringsSep "\n" (ip: "${ip} ${name} ${name}.${domain}") ips
          ) machines
        );
      };
  };
}
