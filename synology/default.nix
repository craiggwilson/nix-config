{ lib, ... }:
let
  stacks = {
    homeassistant = import ./stacks/homeassistant.nix { inherit lib; };
    paperless = import ./stacks/paperless.nix { };
    yuvomi = import ./stacks/yuvomi.nix { };
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
          pkgs.coreutils
          pkgs.openssh
          pkgs.secretspec
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

          if [[ -z ''${SECRETSPEC_FILE:-} || ! -r "$SECRETSPEC_FILE" ]]; then
            echo "SecretSpec manifest is unavailable." >&2
            echo "Apply the Home Manager configuration, then retry." >&2
            exit 1
          fi

          umask 077

          ${lib.concatMapStringsSep "\n"
            (
              stackName:
              let
                stackDefinition = stacks.${stackName};
              in
              ''
                if [[ "$stack" == ${lib.escapeShellArg stackName} ]]; then
                  ${lib.concatMapStringsSep "\n" (
                    secretPath:
                    let
                      secretName = stackDefinition.secrets.${secretPath};
                    in
                    ''
                        targetFile="$localDirectory/${secretPath}"
                        mkdir -p "$(dirname "$targetFile")"
                        temporaryFile=$(mktemp "$targetFile.XXXXXX")
                        trap 'rm -f "$temporaryFile"' EXIT
                      secretspec get ${lib.escapeShellArg secretName} --file "$SECRETSPEC_FILE" > "$temporaryFile"
                        chmod 600 "$temporaryFile"
                        mv -f "$temporaryFile" "$targetFile"
                        trap - EXIT
                    ''
                  ) (builtins.attrNames (stackDefinition.secrets or { }))}
                fi
              ''
            )
            (
              builtins.filter (stackName: builtins.attrNames (stacks.${stackName}.secrets or { }) != [ ]) (
                builtins.attrNames stacks
              )
            )
          }

          # Copy only Nix-managed stack files through the local SMB mount.
          # Files created by the application remain on the NAS. Refuse to
          # overwrite a file changed outside Nix; review it before retrying.
          while IFS= read -r -d "" sourceFile; do
            relativePath="''${sourceFile#"$stackDirectory/"}"
            targetFile="$localDirectory/$relativePath"
            if [[ -e "$targetFile" ]] && ! cmp --silent "$sourceFile" "$targetFile"; then
              echo "refusing to overwrite changed file: $targetFile" >&2
              printf 'run this to see the delta:\n  diff -u %q %q\n' \
                "$targetFile" "$sourceFile" >&2
              exit 1
            fi
          done < <(find -L "$stackDirectory" -type f -print0)

          # Empty directories are meaningful for bind mounts too. Create the
          # declared stack directories without changing any existing contents.
          while IFS= read -r -d "" sourceDirectory; do
            relativePath="''${sourceDirectory#"$stackDirectory/"}"
            mkdir -p "$localDirectory/$relativePath"
          done < <(find -L "$stackDirectory" -mindepth 1 -type d -print0)

          while IFS= read -r -d "" sourceFile; do
            relativePath="''${sourceFile#"$stackDirectory/"}"
            targetFile="$localDirectory/$relativePath"
            if [[ ! -e "$targetFile" ]]; then
              mkdir -p "$(dirname "$targetFile")"
              # Nix store files are read-only; do not carry that mode onto
              # mutable files on the NAS share.
              cp --no-preserve=mode "$sourceFile" "$targetFile"
            fi
          done < <(find -L "$stackDirectory" -type f -print0)

          # SSH is only used for the Docker Compose lifecycle operation.
          # Synology's command-mode PATH omits /usr/local/bin, and its Docker
          # socket requires root even when the interactive login can find the
          # client. A TTY lets sudo prompt for the account password once.
          # shellcheck disable=SC2029
          ssh -tt "$host" "cd '$remoteDirectory' && sudo /usr/local/bin/docker compose pull && sudo /usr/local/bin/docker compose up -d"
        '';
      };
  };
}
