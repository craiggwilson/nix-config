{ lib, ... }:
{
  config.substrate.modules.networking.dns = {
    tags = [ "networking:dns" ];

    generic = {
      options.hdwlinux.networking.dns.providers = lib.mkOption {
        type = lib.types.listOf (
          lib.types.attrTag {
            nextdns = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  name = lib.mkOption {
                    type = lib.types.str;
                    description = "Provider name, used as `hdwlinux dns <name>`.";
                  };

                  secretPath = lib.mkOption {
                    type = lib.types.str;
                    description = "Path to a file containing the NextDNS profile id (optionally 'device-id' prefixed for per-device identity in NextDNS logs). The DNS-over-TLS server list is built from it at runtime.";
                  };
                };
              };
            };

            cloudflare = lib.mkOption {
              type = lib.types.submodule {
                options.name = lib.mkOption {
                  type = lib.types.str;
                  description = "Provider name, used as `hdwlinux dns <name>`. Uses Cloudflare's malware-blocking DNS-over-TLS servers.";
                };
              };
            };

            plain = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  name = lib.mkOption {
                    type = lib.types.str;
                    description = "Provider name, used as `hdwlinux dns <name>`.";
                  };

                  servers = lib.mkOption {
                    type = lib.types.nonEmptyListOf lib.types.str;
                    description = "Unencrypted DNS server addresses.";
                  };
                };
              };
            };
          }
        );
        default = [ ];
        example = lib.literalExpression ''
          [
            {
              nextdns = {
                name = "nextdns";
                secretPath = config.hdwlinux.security.secrets.entries.dnsNextdnsProfile.path;
              };
            }
            { cloudflare.name = "cloudflare"; }
            { plain = { name = "router"; servers = [ "192.168.1.1" ]; }; }
          ]
        '';
        description = ''
          Ordered DNS providers. The first entry is the default; later
          entries are selectable with `hdwlinux dns <name>`. Selecting a
          provider replaces the link's DNS servers outright — network
          (DHCP) DNS is never mixed in, since systemd-resolved has no
          per-server fallback ordering on a link. Use `hdwlinux dns off`
          to return to network DNS. An empty list disables this module
          entirely.
        '';
      };
    };

    nixos =
      { config, pkgs, ... }:
      let
        cfg = config.hdwlinux.networking.dns;

        # attrTag values are single-attribute sets: { <tag> = { ... }; }
        providerTag = p: builtins.head (builtins.attrNames p);
        providerName = p: (builtins.head (builtins.attrValues p)).name;

        cloudflareServers = [
          "1.1.1.1#security.cloudflare-dns.com"
          "1.0.0.1#security.cloudflare-dns.com"
          "2606:4700:4700::1111#security.cloudflare-dns.com"
          "2606:4700:4700::1001#security.cloudflare-dns.com"
        ];

        providerCase =
          p:
          let
            b = builtins.head (builtins.attrValues p);
          in
          builtins.getAttr (providerTag p) {
            nextdns = ''
              ${lib.escapeShellArg b.name})
                local profile_file=${lib.escapeShellArg b.secretPath}
                if [[ ! -r "$profile_file" ]]; then
                  echo "hdwlinux-dns: $profile_file missing; leaving $dev on network DNS" >&2
                  return 0
                fi
                local raw profile
                raw="$(<"$profile_file")"
                profile="''${raw//[$'\n\r\t ']/}"
                SERVERS="45.90.28.0#$profile.dns.nextdns.io 45.90.30.0#$profile.dns.nextdns.io 2a07:a8c0::#$profile.dns.nextdns.io 2a07:a8c1::#$profile.dns.nextdns.io"
                tls=yes
                ;;'';
            cloudflare = ''
              ${lib.escapeShellArg b.name})
                SERVERS=${lib.escapeShellArg (lib.concatStringsSep " " cloudflareServers)}
                tls=yes
                ;;'';
            plain = ''
              ${lib.escapeShellArg b.name})
                SERVERS=${lib.escapeShellArg (lib.concatStringsSep " " b.servers)}
                tls=no
                ;;'';
          };

        dnsScript = pkgs.writeShellScript "hdwlinux-dns" ''
          set -u

          STATE_FILE=/var/lib/hdwlinux/dns-provider
          RESOLVECTL=${lib.getExe' pkgs.systemd "resolvectl"}
          NMCLI=${lib.getExe' pkgs.networkmanager "nmcli"}
          DEFAULT_PROVIDER=${lib.escapeShellArg (providerName (lib.head cfg.providers))}
          PROVIDER_NAMES=${lib.escapeShellArg (lib.concatStringsSep " " (map providerName cfg.providers))}

          SERVERS=""

          apply_link() {
            local dev="$1" provider="" tls=""
            if [[ -r "$STATE_FILE" ]]; then
              read -r provider < "$STATE_FILE"
            fi
            [[ -z "$provider" ]] && provider="$DEFAULT_PROVIDER"

            SERVERS=""
            case "$provider" in
              off)
                # `resolvectl revert` wipes the link's servers and NM's
                # `reapply` is a no-op when the connection is unchanged, so
                # set NetworkManager's DHCP-provided servers back explicitly.
                local servers="" raw
                for fam in IP4 IP6; do
                  raw="$("$NMCLI" -g "$fam.DNS" device show "$dev" 2>/dev/null || true)"
                  raw="''${raw// \| / }"
                  [[ -n "$raw" ]] && servers="$servers $raw"
                done
                if [[ -z "$servers" ]]; then
                  "$RESOLVECTL" revert "$dev"
                else
                  "$RESOLVECTL" domain "$dev" '~.'
                  "$RESOLVECTL" dns "$dev" $servers
                  "$RESOLVECTL" dnsovertls "$dev" no
                fi
                return 0
                ;;
              ${lib.concatMapStringsSep "\n" providerCase cfg.providers}
              *)
                echo "hdwlinux-dns: unknown provider '$provider' (known: $PROVIDER_NAMES off)" >&2
                return 1
                ;;
            esac

            "$RESOLVECTL" domain "$dev" '~.'
            "$RESOLVECTL" dns "$dev" $SERVERS
            "$RESOLVECTL" dnsovertls "$dev" "$tls"
          }

          case "''${1:-}" in
            apply-all)
              ${lib.getExe' pkgs.coreutils "mkdir"} -p /var/lib/hdwlinux
              if [[ -n "''${2:-}" ]]; then
                printf '%s\n' "$2" > "$STATE_FILE"
              fi
              rc=0
              while IFS=: read -r dev type state; do
                if [[ "$state" == "connected" && ( "$type" == "ethernet" || "$type" == "wifi" ) ]]; then
                  apply_link "$dev" || rc=1
                fi
              done < <("$NMCLI" -t -f DEVICE,TYPE,STATE device)
              exit "$rc"
              ;;
            *)
              # NetworkManager dispatcher invocation: $1=device $2=action.
              case "''${2:-}" in
                up|dhcp4-change|dhcp6-change|connectivity-change)
                  apply_link "$1"
                  ;;
              esac
              ;;
          esac
        '';
      in
      {
        config = lib.mkIf (cfg.providers != [ ]) {
          assertions = [
            {
              assertion =
                let
                  names = map providerName cfg.providers;
                in
                lib.unique names == names;
              message = "hdwlinux.networking.dns.providers names must be unique.";
            }
          ];

          # The resolved module points NetworkManager at systemd-resolved, so
          # network-advertised DNS still flows per-link as a bootstrap.
          services.resolved.enable = true;

          environment.etc."NetworkManager/dispatcher.d/20-hdwlinux-dns".source = dnsScript;

          # Covers secret-backed providers arriving after the link came up.
          systemd.services.hdwlinux-dns-apply = {
            description = "Apply DNS providers to connected links";
            wantedBy = [ "multi-user.target" ];
            after = [
              "network-online.target"
              "opnix-secrets.service"
            ];
            wants = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${dnsScript} apply-all";
            };
          };
        };
      };

    # The dispatcher script only exists on hosts tagged networking:dns with
    # providers configured, so the commands simply fail elsewhere.
    homeManager = {
      config.hdwlinux.programs.hdwlinux.subcommands.dns = {
        off = "sudo /etc/NetworkManager/dispatcher.d/20-hdwlinux-dns apply-all off";
        status = "resolvectl status";
        "*" = "sudo /etc/NetworkManager/dispatcher.d/20-hdwlinux-dns apply-all \"$1\"";
      };
    };
  };
}
