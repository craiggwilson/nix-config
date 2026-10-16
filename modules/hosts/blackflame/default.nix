{ inputs, ... }:
let
  hostname = "blackflame";
  diskoConfig = import ./_disko.nix;
in
{
  substrate.hosts.${hostname} = {
    system = "x86_64-linux";
    # Host-local facts: the identity, the machine model, and the location.
    # Modules require these instead of re-claiming them.
    provides = [
      "host:${hostname}"
      "hardware:model:system76-serval-ws"
      "location:raeford"
    ];
    nixpkgsConfig.cudaSupport = true;
    users = [ "craig@personal" ];
    tags = [
      "host:${hostname}"
    ];

    requires = [
      "hardware:audio"
      "hardware:bluetooth"
      "hardware:camera"
      "hardware:firmware"
      "hardware:graphics"
      "hardware:graphics:cuda"
      "hardware:graphics:nvidia"
      "hardware:laptop"
      "hardware:monitors"
      "hardware:networking"
      "hardware:power"
      "hardware:storage"
      "hardware:thunderbolt"

      # System services local to this machine.
      "boot:systemd"
      "networking:dns"
      "hardware:printing"
      "hardware:scanning"

      # Core: minimal cross-class utilities and interfaces, named
      # specifically (there is no bare-core sweep or aggregator; matching
      # is exact, wildcards explicit).
      "core:home"
      "core:interfaces"
      "core:nix"
      "core:networking"
      "core:session"
      "core:ssh"
      "core:systemd"
      "core:utils"
      "core:xdg"

      # Platform maintenance lives in the hardware domain, not core.
    ];
  };

  substrate.modules.hosts.${hostname} = {
    tags = [ "host:${hostname}" ];
    provides = [ "host:${hostname}" ];

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
