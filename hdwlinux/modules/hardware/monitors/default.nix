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
            model = lib.mkOption { type = lib.types.str; };
            serial = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            vendor = lib.mkOption { type = lib.types.str; };
            mode = lib.mkOption { type = lib.types.str; };
            scale = lib.mkOption {
              type = lib.types.float;
              default = 1.0;
            };
            adaptive_sync = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            displaylink = lib.mkOption {
              type = lib.types.bool;
              default = false;
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
      { config, lib, pkgs, ... }:
      let
        monitorsWithEdidOverride = lib.filterAttrs
          (_: monitor: monitor.edidOverride != null)
          config.hdwlinux.hardware.monitors;

        edidDir = pkgs.runCommand "edid-files" { } ''
          mkdir -p $out
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: monitor: ''
            cp ${monitor.edidOverride.edidFile} $out/${name}.bin
          '') monitorsWithEdidOverride)}
        '';

        # Script to apply EDID overrides to connected displays with missing/invalid EDID
        edidFixScript = pkgs.writeShellScript "edid-fix" ''
          set -euo pipefail

          EDID_DIR="${edidDir}"
          DEBUG_DRI="/sys/kernel/debug/dri"

          # Ensure debugfs is mounted
          if ! mountpoint -q /sys/kernel/debug 2>/dev/null; then
            mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null || true
          fi

          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: monitor: ''
            # Look for ${name} (${monitor.model}) on ${monitor.edidOverride.connectorPrefix}* connectors
            EDID_FILE="$EDID_DIR/${name}.bin"
            SERIAL="${monitor.serial or ""}"
            MODEL="${monitor.model}"

            for connector_dir in /sys/class/drm/card*-${monitor.edidOverride.connectorPrefix}*/; do
              [ -d "$connector_dir" ] || continue

              connector=$(basename "$connector_dir")
              status=$(cat "$connector_dir/status" 2>/dev/null || echo "unknown")

              # Only process connected displays
              [ "$status" = "connected" ] || continue

              # Check if EDID exists and is valid
              edid_file="$connector_dir/edid"
              if [ -f "$edid_file" ]; then
                # Check if EDID contains expected serial or is empty/corrupt
                edid_size=$(wc -c < "$edid_file" 2>/dev/null || echo 0)
                if [ "$edid_size" -lt 128 ]; then
                  echo "Connector $connector has invalid EDID (size: $edid_size), checking if override needed..."
                elif [ -n "$SERIAL" ]; then
                  # Check if serial matches (EDID serial is in ASCII at specific offsets)
                  if ! strings "$edid_file" 2>/dev/null | grep -q "$SERIAL"; then
                    # Serial doesn't match, might be wrong EDID or different monitor
                    continue
                  fi
                  # Serial matches but EDID might be incomplete - apply override
                  echo "Connector $connector appears to be ${name}, applying EDID override..."
                else
                  continue
                fi
              else
                echo "Connector $connector has no EDID, checking if override needed..."
              fi

              # Find the DRI debug path for this connector
              # Extract card number and connector name
              card_num=$(echo "$connector" | sed -n 's/card\([0-9]*\)-.*/\1/p')
              conn_name=$(echo "$connector" | sed 's/card[0-9]*-//')

              override_path="$DEBUG_DRI/$card_num/$conn_name/edid_override"

              if [ -f "$override_path" ]; then
                echo "Applying ${name} EDID to $conn_name via $override_path"
                cat "$EDID_FILE" > "$override_path" 2>/dev/null || echo "Failed to write EDID override for $conn_name"

                # Trigger re-detection
                status_file="$connector_dir/../card''${card_num}-''${conn_name}/status"
                if [ -f "$status_file" ] && [ -w "$status_file" ]; then
                  echo detect > "$status_file" 2>/dev/null || true
                fi
              fi
            done
          '') monitorsWithEdidOverride)}
        '';
      in
      lib.mkIf (monitorsWithEdidOverride != { }) {
        environment.etc."hdwlinux/edid-fix".source = edidFixScript;

        boot.postBootCommands = ''
          sleep 2
          /etc/hdwlinux/edid-fix || true
        '';

        powerManagement.resumeCommands = ''
          sleep 3
          /etc/hdwlinux/edid-fix || true
        '';
      };
  };
}
