{
  config,
  lib,
  pkgs,
  flake,
  inputs,
  ...
}:

let
  cfg = config.hdwlinux.programs.hdwlinux2;
  user = config.snowfallorg.user.name;
  privatePath = "${inputs.secrets}/home/${user}";
  privateExists = builtins.pathExists privatePath;
  privateCmd = if privateExists then " --override-input secrets ${flake}/../nix-private" else "";
in
{
  options.hdwlinux.programs.hdwlinux2 = {
    enable = lib.hdwlinux.mkEnableOption "hdwlinux2" true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.hdwlinux.writeJustApplication {
        name = "hdwlinux2";
        runtimeInputs = [
          pkgs.just
          pkgs.nix
          pkgs.nix-output-monitor
          pkgs.nvd
          pkgs.system76-power
        ];
        modules = {
          "*" = ''
            default:
              just -f "{{justfile()}}" --list 

            # git alias for the system's flake.
            config *args:
              git -C ${flake} {{args}}
          '';
          battery = ''
            default: get-profile

            # gets the battery's profile.
            get-profile:
              system76-power charge-thresholds

            # sets the battery's profile.
            set-profile profile="max_lifespan":
              system76-power charge-thresholds --profile {{profile}} 
          '';
          firmware = ''
            # schedules a firmware update.
            update:
              sudo system76-firmware-cli schedule
          '';
          os = {
            "*" = ''
              # updates the system's flake.
              update *args:
                nix flake update --flake ${flake} {{args}}
            '';
            switch = ''
              default: local

              # builds the local system and switches to it.
              local:
                @git -C ${flake} add -A .
                sudo nixos-rebuild switch --flake ${flake}${privateCmd} "$@" |& nom

              # builds the remove system and switches to it.
              remote system addr:
                @git -C ${flake} add -A .
                nixos-rebuild switch --flake "${flake}#{{system}}"${privateCmd} --target-host "${user}@{{addr}}" --use-remote-sudo "$@" |& nom
            '';
          };
          packages = ''
            # lists the system's packages.
            list:
              nvd list

            # runs a package.
            run name *args:
              nix run "nixpkgs#$1" -- "''${@:2}"

            # opens a shell with the given packages added to the path.
            shell +packages:
              nix-shell --command "$SHELL" -p {{packages}}

            # provides information on why a package is installed.
            why-depends name:
              nix why-depends /run/current-system "nixpkgs#{{name}}" --all
          '';
        };
      })
    ];
  };
}
