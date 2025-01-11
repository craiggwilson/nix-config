{
  config,
  lib,
  pkgs,
  flake,
  inputs,
  ...
}:

let
  cfg = config.hdwlinux.programs.hdwlinux;
  user = config.snowfallorg.user.name;
  privatePath = "${inputs.secrets}/${user}";
  privateExists = builtins.pathExists privatePath;
  plainCmd = "nixos-rebuild switch --flake ${flake}";
  privateCmd = if privateExists then " --override-input secrets ${flake}/../nix-private" else "";
in
{
  options.hdwlinux.programs.hdwlinux = {
    enable = lib.hdwlinux.mkEnableOption "hdwlinux" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
        name = "hdwlinux";
        runtimeInputs = [
          pkgs.nix
          pkgs.nix-output-monitor
          pkgs.nvd
        ];
        subcommands = {
          config = "git -C ${flake} \"$@\"";
          flake = {
            update = "nix flake update --flake ${flake} \"$@\"";
            "*" = "echo ${flake}";
          };
          generations = {
            delete-older-than = "nix-collect-garbage --delete-older-than \"$@\"";
            diff = {
              newest = ''nvd diff "$(find /nix/var/nix/profiles/system-*-link | tail -2)"'';
              "*" = ''nvd diff "/nix/var/nix/profiles/system-$1-link" "/nix/var/nix/profiles/system-$2-link"'';
            };
            diff-closures = {
              newest = ''nix store diff-closures "$(find /nix/var/nix/profiles/system-*-link | tail -2)"'';
              "*" =
                ''nix store diff-closures "/nix/var/nix/profiles/system-$1-link" "/nix/var/nix/profiles/system-$2-link"'';
            };
            list = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
          };
          packages = {
            list = "nvd list";
          };
          switch = {
            remote = ''
              hostname="$1"
              addr="$2"
              shift 2
              git -C ${flake} add -A . && "${plainCmd}#$hostname${privateCmd}" --target-host "${user}@$addr" --use-remote-sudo "$@" |& nom
            '';
            "*" = ''git -C ${flake} add -A . && sudo ${plainCmd}${privateCmd} "$@" |& sudo nom'';
          };
        };
      })
    ];
  };
}
