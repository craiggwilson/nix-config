{ inputs, ... }:
let
  hostname = "blackflame";
  diskoConfig = import ./_disko.nix;
in
{
  substrate.hosts.${hostname} = {
    system = "x86_64-linux";
    nixpkgsConfig.cudaSupport = true;
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

        secretspec.entries = {
          nextDnsBlockedProfile = {
            description = "NextDNS profile id for the malware-blocking configuration.";
            ref = {
              vault = "Craig";
              item = "NextDNS";
              field = "blocked-profile";
            };
            file = { };
          };
          nextDnsUnblockedProfile = {
            description = "NextDNS profile id for the unblocked configuration.";
            ref = {
              vault = "Craig";
              item = "NextDNS";
              field = "unblocked-profile";
            };
            file = { };
          };
        };
        hdwlinux.networking.dns.providers = [
          {
            nextdns = {
              name = "nextdns-blocked";
              secretPath = config.secretspec.entries.nextDnsBlockedProfile.file.path;
            };
          }
          {
            nextdns = {
              name = "nextdns-unblocked";
              secretPath = config.secretspec.entries.nextDnsUnblockedProfile.file.path;
            };
          }
          { cloudflare.name = "cloudflare"; }
        ];

        hdwlinux.theme.system = "catppuccin";
        system.stateVersion = "23.05";
      };
  };
}
