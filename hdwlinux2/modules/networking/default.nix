{ lib, ... }:
let
  domainOption = lib.mkOption {
    description = "The domain to use for networking (e.g., for printers, services).";
    type = lib.types.str;
    default = "";
  };
in
{
  config.substrate.modules.networking = {
    tags = [ "networking" ];
    nixos = {
      options.hdwlinux.networking.domain = domainOption;

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
    homeManager = {
      options.hdwlinux.networking.domain = domainOption;
    };
  };
}
