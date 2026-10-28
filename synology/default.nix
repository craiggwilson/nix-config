{ lib, ... }:
let
  stacks = {
    homeassistant = import ./stacks/homeassistant.nix { inherit lib; };
  };

  mkStack =
    pkgs: name: stack:
    pkgs.runCommand "synology-stack-${name}" { } ''
      mkdir -p $out
      ${lib.concatMapStringsSep "\n" (directory: "mkdir -p $out/${lib.escapeShellArg directory}") (
        stack.directories or [ ]
      )}
      cp ${(pkgs.formats.yaml { }).generate "compose.yaml" stack.compose} $out/compose.yaml
      ${lib.concatMapStringsSep "\n" (
        fileName:
        "mkdir -p $out/$(dirname ${lib.escapeShellArg fileName}) && cp ${
          pkgs.writeText fileName stack.files.${fileName}
        } $out/${lib.escapeShellArg fileName}"
      ) (builtins.attrNames (stack.files or { }))}
    '';

  mkStacks =
    pkgs:
    pkgs.linkFarm "synology-stacks" (
      lib.mapAttrsToList (name: stack: {
        inherit name;
        path = mkStack pkgs name stack;
      }) stacks
    );
in
{
  config.substrate.publish.packages = {
    synology-stacks =
      { pkgs, ... }:
      mkStacks pkgs;

    synology-deploy =
      { pkgs, ... }:
      pkgs.writeShellApplication {
        name = "synology-deploy";
        runtimeInputs = [
          pkgs.openssh
          pkgs.rsync
        ];
        text = ''
          if [[ $# -lt 2 || $# -gt 3 ]]; then
            echo "usage: synology-deploy HOST STACK [REMOTE_DIRECTORY]" >&2
            exit 2
          fi

          host="$1"
          stack="$2"
          remoteDirectory="''${3:-/volume3/docker/$stack}"
          stackDirectory=${mkStacks pkgs}/"$stack"
          mountRoot="''${SYNOLOGY_MOUNT:-$HOME/mnt/synology/docker}"
          localDirectory="$mountRoot/$stack"

          if [[ ! "$stack" =~ ^[a-z0-9][a-z0-9-]*$ || ! -d "$stackDirectory" ]]; then
            echo "unknown Synology stack: $stack" >&2
            echo "available stacks: ${lib.concatStringsSep ", " (builtins.attrNames stacks)}" >&2
            exit 2
          fi

          if [[ ! -d "$localDirectory" ]]; then
            echo "Synology SMB mount is not available: $localDirectory" >&2
            echo "Mount the docker share or set SYNOLOGY_MOUNT." >&2
            exit 1
          fi

          # Sync only Nix-managed stack files through the local SMB mount.
          # Files created by the application remain on the NAS.
          rsync --archive --checksum "$stackDirectory/" "$localDirectory/"

          # SSH is only used for the Docker Compose lifecycle operation.
          # shellcheck disable=SC2029
          ssh "$host" "cd '$remoteDirectory' && docker compose pull && docker compose up -d"
        '';
      };

    synology-pull =
      { pkgs, ... }:
      pkgs.writeShellApplication {
        name = "synology-pull";
        runtimeInputs = [ pkgs.rsync ];
        text = ''
          if [[ $# -ne 2 ]]; then
            echo "usage: synology-pull STACK DESTINATION" >&2
            exit 2
          fi

          stack="$1"
          destination="$2"
          mountRoot="''${SYNOLOGY_MOUNT:-$HOME/mnt/synology/docker}"
          source="$mountRoot/$stack"

          if [[ ! -d "$source" ]]; then
            echo "Synology SMB mount is not available: $source" >&2
            echo "Mount the docker share or set SYNOLOGY_MOUNT." >&2
            exit 1
          fi

          mkdir -p "$destination"
          rsync --archive --checksum \
            --exclude='.storage/' \
            --exclude='home-assistant_v2.db*' \
            --exclude='home-assistant.log*' \
            --exclude='secrets.yaml' \
            --exclude='custom_components/' \
            --exclude='compose.yaml' \
            "$source/" "$destination/"
        '';
      };
  };
}
