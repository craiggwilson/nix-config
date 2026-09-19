{
  config.substrate.modules.services.kdeconnect = {
    tags = [ "desktop" ];

    nixos =
      {
        config,
        lib,
        ...
      }:
      let
        portRange = "1714:1764";

        acceptFromLan = cidr: ''
          iptables -w -A nixos-fw -p tcp -s ${cidr} --dport ${portRange} -j nixos-fw-accept
          iptables -w -A nixos-fw -p udp -s ${cidr} --dport ${portRange} -j nixos-fw-accept
        '';

        lanRules = lib.concatMapStrings acceptFromLan config.hdwlinux.networking.lanCidrs;

        tailnetRules = lib.optionalString config.services.tailscale.enable ''
          ip46tables -A nixos-fw -i tailscale0 -p tcp --dport ${portRange} -j nixos-fw-accept
          ip46tables -A nixos-fw -i tailscale0 -p udp --dport ${portRange} -j nixos-fw-accept
        '';
      in
      {
        networking.firewall.extraCommands = lanRules + tailnetRules;
      };

    homeManager = {
      services.kdeconnect = {
        enable = true;
      };
    };
  };
}
