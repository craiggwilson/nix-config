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
    homeManager =
      { pkgs, ... }:
      {
        options.hdwlinux.networking.domain = domainOption;

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
