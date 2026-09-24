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

    homeManager = { pkgs, ... }: {
      # pkgs.gdbus is required by noctalia's icefish/phone-connect plugin for
      # DBus device discovery; the home-manager kdeconnect service alone does
      # not put it on PATH.
      home.packages = [
        pkgs.glib.bin
      ];

      services.kdeconnect = {
        enable = true;
      };

      # The kdeconnect-kde package ships an XDG autostart entry for the daemon;
      # uwsm's autostart generator turns it into a second unit that races the
      # home-manager one for the org.kde.kdeconnect D-Bus name (loser exits 0).
      # A same-named Hidden=true user entry suppresses it so the declarative
      # unit is the only daemon starter.
      xdg.configFile."autostart/org.kde.kdeconnect.daemon.desktop".text = ''
        [Desktop Entry]
        Hidden=true
      '';
    };
  };
}
