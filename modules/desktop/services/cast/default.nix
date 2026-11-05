{
  config.substrate.modules.desktop.services.cast = {
    tags = [ "desktop" ];

    nixos =
      { lib, pkgs, ... }:
      let
        castSupport = pkgs.writeShellScript "cast-support" ''
          set -eu

          rule_present() {
            ${pkgs.iptables}/bin/iptables -C nixos-fw "$@" 2>/dev/null
          }

          add_rule() {
            rule_present "$@" || ${pkgs.iptables}/bin/iptables -I nixos-fw 1 "$@"
          }

          remove_rule() {
            rule_present "$@" && ${pkgs.iptables}/bin/iptables -D nixos-fw "$@" || true
          }

          add_lan_rules() {
            for cidr in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
              add_rule -s "$cidr" "$@"
            done
          }

          remove_lan_rules() {
            for cidr in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
              remove_rule -s "$cidr" "$@"
            done
          }

          case "$1" in
            start)
              ${pkgs.coreutils}/bin/touch /run/cast-support-enabled
              if ! ${pkgs.systemd}/bin/systemctl start avahi-daemon.service; then
                ${pkgs.coreutils}/bin/rm -f /run/cast-support-enabled
                exit 1
              fi
              add_lan_rules -p udp --dport 5353 -j nixos-fw-accept
              add_lan_rules -p tcp --dport 47830 -j nixos-fw-accept
              ;;
            start-airplay)
              ${pkgs.coreutils}/bin/touch /run/cast-support-enabled
              if ! ${pkgs.systemd}/bin/systemctl start avahi-daemon.service; then
                ${pkgs.coreutils}/bin/rm -f /run/cast-support-enabled
                exit 1
              fi
              add_lan_rules -p udp --dport 5353 -j nixos-fw-accept
              add_lan_rules -p tcp --dport 47830 -j nixos-fw-accept
              add_lan_rules -p udp --dport 47840:47849 -j nixos-fw-accept
              ;;
            stop)
              remove_lan_rules -p udp --dport 47840:47849 -j nixos-fw-accept
              remove_lan_rules -p tcp --dport 47830 -j nixos-fw-accept
              remove_lan_rules -p udp --dport 5353 -j nixos-fw-accept
              ${pkgs.systemd}/bin/systemctl stop avahi-daemon.service
              ${pkgs.coreutils}/bin/rm -f /run/cast-support-enabled
              ;;
            *)
              echo "usage: $0 start|start-airplay|stop" >&2
              exit 2
              ;;
          esac
        '';
      in
      {
        services.avahi = {
          enable = true;
          openFirewall = false;
        };

        # Avahi is present but deliberately not started until a Cast mode is enabled.
        systemd.services.avahi-daemon.wantedBy = lib.mkForce [ ];
        systemd.services.avahi-daemon.unitConfig.ConditionPathExists = "/run/cast-support-enabled";
        systemd.sockets.avahi-daemon.wantedBy = lib.mkForce [ ];

        systemd.services.cast-support-chromecast = {
          description = "Enable Dux Cast network support";
          after = [ "firewall.service" ];
          partOf = [ "firewall.service" ];
          wantedBy = [ ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${castSupport} start";
            ExecStop = "${castSupport} stop";
          };
        };

        systemd.services.cast-support-airplay = {
          description = "Enable Dux Cast network support with AirPlay";
          after = [ "firewall.service" ];
          partOf = [ "firewall.service" ];
          wantedBy = [ ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${castSupport} start-airplay";
            ExecStop = "${castSupport} stop";
          };
        };
      };

    homeManager =
      { pkgs, ... }:
      let
        castHelper = pkgs.hdwlinux.cast-helper;
        doubletake = pkgs.hdwlinux.doubletake;
        castPackages = [
          castHelper
          doubletake
          pkgs.gst_all_1.gstreamer
          pkgs.gst_all_1.gst-plugins-base
          pkgs.gst_all_1.gst-plugins-good
          pkgs.gst_all_1.gst-plugins-bad
          pkgs.gst_all_1.gst-libav
          pkgs.pipewire
          pkgs.libheif
          pkgs.pulseaudio
        ];
      in
      {
        home.packages = castPackages;

        hdwlinux.programs.hdwlinux = {
          runtimeInputs = castPackages ++ [
            pkgs.sudo
            pkgs.systemd
          ];
          subcommands.cast = {
            enable = "sudo systemctl start cast-support-chromecast.service cast-support-airplay.service";
            enable-chromecast = "sudo systemctl start cast-support-chromecast.service";
            enable-airplay = "sudo systemctl start cast-support-airplay.service";
            disable = "sudo systemctl stop cast-support-airplay.service cast-support-chromecast.service";
            status = ''
              chromecast=false
              airplay=false
              systemctl is-active --quiet cast-support-chromecast.service && chromecast=true
              systemctl is-active --quiet cast-support-airplay.service && airplay=true

              case "$chromecast:$airplay" in
                true:true) echo "enabled (Chromecast + AirPlay)" ;;
                true:false) echo "enabled (Chromecast)" ;;
                false:true) echo "enabled (AirPlay)" ;;
                false:false) echo "disabled" ;;
              esac
            '';
          };
        };

      };
  };
}
