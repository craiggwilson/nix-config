{ lib, ... }:
let
  stacks = {
    homeassistant = import ./stacks/homeassistant.nix;
  };

  mkStack =
    pkgs: name: stack:
    pkgs.runCommand "synology-stack-${name}" { } ''
      mkdir -p $out
      cp ${(pkgs.formats.yaml { }).generate "compose.yaml" stack.compose} $out/compose.yaml
      ${lib.concatMapStringsSep "\n" (
        fileName:
        "cp ${pkgs.writeText fileName stack.files.${fileName}} $out/${lib.escapeShellArg fileName}"
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

          if [[ ! "$stack" =~ ^[a-z0-9][a-z0-9-]*$ || ! -d "$stackDirectory" ]]; then
            echo "unknown Synology stack: $stack" >&2
            echo "available stacks: ${lib.concatStringsSep ", " (builtins.attrNames stacks)}" >&2
            exit 2
          fi

          # The directory is deliberately interpreted by the remote shell so
          # the same path is used by mkdir, rsync, and docker compose.
          # shellcheck disable=SC2029
          ssh "$host" "mkdir -p '$remoteDirectory'"
          rsync --archive --checksum \
            "$stackDirectory/" \
            "$host:$remoteDirectory/"
          # shellcheck disable=SC2029
          ssh "$host" "cd '$remoteDirectory' && docker compose pull && docker compose up -d"
        '';
      };
  };
}
