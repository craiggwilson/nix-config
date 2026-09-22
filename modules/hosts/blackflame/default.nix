{ inputs, ... }:
let
  hostname = "blackflame";
  diskoConfig = import ./_disko.nix;
in
{
  substrate.hosts.${hostname} = {
    system = "x86_64-linux";
    users = [ "craig@personal" ];
    tags = [
      "host:${hostname}"
    ];
  };

  substrate.modules.hosts.${hostname} = {
    tags = [ "host:${hostname}" ];

    nixos =
      { config, ... }:
      {
        imports = [
          inputs.disko.nixosModules.disko
          diskoConfig
        ];

        hdwlinux.security.secrets.entries.dnsNextdnsProfile.reference =
          "op://Craig/NextDNS/blocked-profile";
        hdwlinux.networking.dns.providers = [
          {
            nextdns = {
              name = "nextdns";
              secretPath = config.hdwlinux.security.secrets.entries.dnsNextdnsProfile.path;
            };
          }
          { cloudflare.name = "cloudflare"; }
        ];

        hdwlinux.theme.system = "catppuccin";
        system.stateVersion = "23.05";
      };
  };
}
