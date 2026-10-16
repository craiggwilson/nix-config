{
  config.substrate.modules.core.networking = {
    provides = [ "core:networking" ];

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
