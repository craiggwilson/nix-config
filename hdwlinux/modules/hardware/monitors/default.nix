{
  config.substrate.modules.hardware.monitors-fix = {
    tags = [ "gui" ];
    generic =
      { lib, ... }:
      let
        edidOverrideType = lib.types.submodule {
          options = {
            edidFile = lib.mkOption {
              type = lib.types.path;
              description = "Path to the EDID binary file.";
            };
            connectorPrefix = lib.mkOption {
              type = lib.types.str;
              default = "DP-";
              description = "Connector prefix to search for (e.g., DP-, HDMI-A-).";
            };
          };
        };

        monitorType = lib.types.submodule {
          options = {
            model = lib.mkOption {
              type = lib.types.str;
              description = "Monitor model name for identification.";
            };
            serial = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Monitor serial number for unique identification.";
            };
            vendor = lib.mkOption {
              type = lib.types.str;
              description = "Monitor vendor/manufacturer name.";
            };
            mode = lib.mkOption {
              type = lib.types.str;
              description = "Display mode (resolution and refresh rate, e.g., '2560x1440@165').";
            };
            scale = lib.mkOption {
              type = lib.types.float;
              default = 1.0;
              description = "Display scaling factor.";
            };
            adaptive_sync = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to enable adaptive sync (VRR/FreeSync/G-Sync).";
            };
            displaylink = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether this monitor uses a DisplayLink adapter.";
            };
            edidOverride = lib.mkOption {
              type = lib.types.nullOr edidOverrideType;
              default = null;
              description = "Override EDID for monitors that don't reliably send EDID on boot/resume.";
            };
          };
        };
      in
      {
        options.hdwlinux.hardware.monitors = lib.mkOption {
          description = "Monitor configurations that can be referenced by name.";
          type = lib.types.attrsOf monitorType;
          default = { };
        };
      };

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        monitorsWithEdidOverride = lib.filterAttrs (
          _: monitor: monitor.edidOverride != null
        ) config.hdwlinux.hardware.monitors;

        edidDir = pkgs.runCommand "edid-files" { } ''
          mkdir -p $out
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: monitor: ''
              cp ${monitor.edidOverride.edidFile} $out/${name}.bin
            '') monitorsWithEdidOverride
          )}
        '';

        edidFixScript = pkgs.writeShellScript "edid-fix" ''
          set -euo pipefail

          EDID_DIR="${edidDir}"
          DEBUG_DRI="/sys/kernel/debug/dri"

          if ! mountpoint -q /sys/kernel/debug 2>/dev/null; then
            mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null || true
          fi

          apply_edid_override() {
            local connector="$1"
            local edid_file="$2"
            local name="$3"

            local card_num=$(echo "$connector" | sed -n 's/card\([0-9]*\)-.*/\1/p')
            local conn_name=$(echo "$connector" | sed 's/card[0-9]*-//')
            local override_path="$DEBUG_DRI/$card_num/$conn_name/edid_override"
            local status_path="/sys/class/drm/$connector/status"

            if [ -f "$override_path" ]; then
              echo "Applying $name EDID to $conn_name"
              if cat "$edid_file" > "$override_path" 2>/dev/null; then
                echo "Resetting connector $conn_name"
                echo off > "$status_path" 2>/dev/null || true
                sleep 1
                echo on > "$status_path" 2>/dev/null || true
                return 0
              else
                echo "Failed to write EDID override for $conn_name"
                return 1
              fi
            else
              echo "No edid_override file at $override_path"
              return 1
            fi
          }

          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: monitor: ''
              EDID_FILE="$EDID_DIR/${name}.bin"
              SERIAL="${monitor.serial or ""}"

              for connector_dir in /sys/class/drm/card*-${monitor.edidOverride.connectorPrefix}*/; do
                [ -d "$connector_dir" ] || continue

                connector=$(basename "$connector_dir")
                conn_status=$(cat "$connector_dir/status" 2>/dev/null || echo "unknown")
                [ "$conn_status" = "connected" ] || continue

                edid_path="$connector_dir/edid"
                needs_override=false

                if [ ! -f "$edid_path" ]; then
                  needs_override=true
                else
                  edid_size=$(wc -c < "$edid_path" 2>/dev/null || echo 0)
                  if [ "$edid_size" -lt 128 ]; then
                    needs_override=true
                  fi
                fi

                if [ "$needs_override" = "true" ]; then
                  echo "Connector $connector needs EDID override (${name})"
                  apply_edid_override "$connector" "$EDID_FILE" "${name}" || true
                fi
              done
            '') monitorsWithEdidOverride
          )}
        '';
      in
      lib.mkIf (monitorsWithEdidOverride != { }) {
        environment.etc."hdwlinux/edid-fix".source = edidFixScript;

        boot.postBootCommands = ''
          sleep 10
          /etc/hdwlinux/edid-fix || true
        '';

        powerManagement.resumeCommands = ''
          sleep 10
          /etc/hdwlinux/edid-fix || true
        '';
      };

    homeManager =
      { pkgs, ... }:
      {
        hdwlinux.programs.hdwlinux = {
          runtimeInputs = [ pkgs.wlr-randr ];
          subcommands.monitors = {
            fix = ''
              if [[ -x /etc/hdwlinux/edid-fix ]]; then
                echo "Running EDID fix script..."
                sudo /etc/hdwlinux/edid-fix
              else
                echo "No EDID fix script found. Forcing DRM connector re-detection..."
                for status in /sys/class/drm/card*/status; do
                  sudo tee "$status" <<< detect >/dev/null 2>&1 || true
                done
              fi
              echo "Done."
            '';
            "*" = ''
              if command -v wlr-randr &>/dev/null; then
                wlr-randr
              else
                echo "wlr-randr not available. Install it for detailed monitor info."
                echo ""
                echo "Connected monitors (basic info):"
                for dir in /sys/class/drm/card*-*/; do
                  if [[ -f "$dir/status" ]]; then
                    status=$(cat "$dir/status" 2>/dev/null || echo "unknown")
                    connector=$(basename "$dir")
                    if [[ "$status" == "connected" ]]; then
                      echo "  $connector"
                    fi
                  fi
                done
              fi
            '';
          };
        };
      };
  };
}
