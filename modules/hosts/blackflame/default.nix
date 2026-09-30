{ inputs, ... }:
let
  hostname = "blackflame";
  diskoConfig = import ./_disko.nix;
in
{
  substrate.hosts.${hostname} = {
    system = "x86_64-linux";
    nixpkgsConfig = {
      cudaSupport = true;
    };
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

        hdwlinux.security.secrets.entries = {
          nextDnsBlockedProfile.reference = "op://Craig/NextDNS/blocked-profile";
          nextDnsUnblockedProfile.reference = "op://Craig/NextDNS/unblocked-profile";
        };
        hdwlinux.networking.dns.providers = [
          {
            nextdns = {
              name = "nextdns-blocked";
              secretPath = config.hdwlinux.security.secrets.entries.nextDnsBlockedProfile.path;
            };
          }
          {
            nextdns = {
              name = "nextdns-unblocked";
              secretPath = config.hdwlinux.security.secrets.entries.nextDnsUnblockedProfile.path;
            };
          }
          { cloudflare.name = "cloudflare"; }
        ];

        theming.active = "catppuccin-mocha";
        system.stateVersion = "23.05";
      };
  };
}
