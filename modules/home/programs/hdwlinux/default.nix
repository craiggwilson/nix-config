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
          pkgs.nix-output-monitor
        ];
        subcommands = {
          generations = {
            list = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
            delete-older-than = "nix-collect-garbage --delete-older-than \"$@\"";
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
          update = "nix flake update --flake ${flake} \"$@\"";
        };
      })
    ];
  };
}
