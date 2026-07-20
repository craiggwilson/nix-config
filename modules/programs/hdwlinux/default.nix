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
        cfg = config.hdwlinux.programs.hdwlinux;
      in
      {
        options.hdwlinux.programs.hdwlinux = {
          subcommands = lib.mkOption {
            type = lib.types.lazyAttrsOf lib.types.anything;
            default = { };
            description = "Additional subcommands to add to the hdwlinux CLI. Other modules can contribute subcommands here.";
          };

          runtimeInputs = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Additional runtime inputs for the hdwlinux CLI. Other modules can contribute packages here.";
          };
        };

        config = lib.mkIf (flake != null) {
          home.packages = [
            (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
              name = "hdwlinux";
              runtimeInputs = [
                pkgs.nix
                pkgs.nvd
              ]
              ++ cfg.runtimeInputs;
              subcommands = {
                config = "git -C ${flake} \"$@\"";
                develop = ''
                  name="$1";
                  shift;
                  nix develop "${flake}#$name" -c "$SHELL" "$@";
                '';
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
              }
              // cfg.subcommands;
            })
          ];
        };
      };
  };
}
