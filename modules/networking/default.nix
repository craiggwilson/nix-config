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
  config.substrate.modules.networking = {
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
    homeManager =
      { pkgs, ... }:
      {
        config.home.packages = [
          pkgs.dnsutils
          pkgs.inetutils
        ];

        config.hdwlinux.programs.hdwlinux = {
          runtimeInputs = [ pkgs.ripgrep ];
          subcommands.wifi = {
            connect = "nmcli connection up \"$@\"";
            disconnect = ''
              active="$(nmcli -t -f active,ssid dev wifi | rg '^yes' | cut -d: -f2)"
              nmcli connection down "$active"
            '';
            off = "nmcli radio wifi off";
            on = "nmcli radio wifi on";
            "*" = ''
              status="$(nmcli radio wifi)"
              if [[ "$status" == 'disabled' ]]; then
                echo "disabled"
              else
                nmcli connection show
              fi
            '';
          };
        };
      };
  };
}
