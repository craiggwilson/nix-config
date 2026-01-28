{
  config.substrate.modules.programs.hdwlinux = {
    tags = [ ]; # Always included

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        flake = config.hdwlinux.flake;
        user = config.hdwlinux.user.name;
        cfg = config.hdwlinux.programs.hdwlinux;
      in
      {
        options.hdwlinux.programs.hdwlinux = {
          subcommands = lib.mkOption {
            type = lib.types.lazyAttrsOf lib.types.raw;
            default = { };
            description = "Additional subcommands to add to the hdwlinux CLI. Other modules can contribute subcommands here.";
          };

          runtimeInputs = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Additional runtime inputs for the hdwlinux CLI. Other modules can contribute packages here.";
          };
        };

        config = {
          home.packages = [
            (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
              name = "hdwlinux";
              runtimeInputs =
                [
                  pkgs.nix
                  pkgs.nix-output-monitor
                  pkgs.nvd
                ]
                ++ cfg.runtimeInputs;
              subcommands =
                {
                  build = {
                    remote = ''
                      hostname="$1"
                      shift
                      git -C ${flake} add -A . && sudo nixos-rebuild build --flake "${flake}#$hostname" "$@"
                    '';
                    "*" = ''git -C ${flake} add -A . && sudo nixos-rebuild build --flake ${flake} "$@"'';
                  };
                  config = "git -C ${flake} \"$@\"";
                  develop = ''
                    name="$1";
                    shift;
                    nix develop "${flake}#$name" -c "$SHELL" "$@";
                  '';
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
                    list = "nixos-rebuild list-generations \"$@\"";
                  };
                  packages = {
                    list = "nvd list";
                    run = ''
                      name="$1";
                      shift;
                      nix run "nixpkgs#$name" -- "$@";
                    '';
                    shell = "nix-shell --command \"$SHELL\" -p \"$@\"";
                    why-depends = "nix why-depends /run/current-system \"nixpkgs#$1\"";
                  };
                  switch = {
                    remote = ''
                      hostname="$1"
                      addr="$2"
                      shift 2
                      git -C ${flake} add -A . && nixos-rebuild switch --flake "${flake}#$hostname" --target-host "${user}@$addr" --sudo "$@" --ask-sudo-password |& nom
                    '';
                    "*" = ''git -C ${flake} add -A . && sudo nixos-rebuild switch --flake ${flake} "$@" |& nom'';
                  };
                  test = ''git -C ${flake} add -A . && sudo nixos-rebuild test --flake ${flake} "$@" |& nom'';
                }
                // cfg.subcommands;
            })
          ];
        };
      };
  };
}
