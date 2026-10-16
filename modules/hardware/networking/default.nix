{ lib, ... }:
let
  domainOption = lib.mkOption {
    description = "The domain to use for networking (e.g., for printers, services).";
    type = lib.types.str;
    default = "";
  };

  lanCidrsOption = lib.mkOption {
    description = "Source CIDRs treated as the local LAN when scoping host services (e.g., KDE Connect).";
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };
in
{
  config.substrate.modules.hardware.networking = {
    provides = [ "hardware:networking" ];
    tags = [ "networking" ];

    generic = {
      options.hdwlinux.networking.domain = domainOption;
      options.hdwlinux.networking.lanCidrs = lanCidrsOption;
    };

    nixos = {
      config.networking = {
        networkmanager = {
          enable = true;
          wifi.backend = "iwd";
        };
        useDHCP = lib.mkDefault true;

        firewall = {
          enable = true;
        };
      };
    };
  };
}
