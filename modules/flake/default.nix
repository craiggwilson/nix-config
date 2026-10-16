{
  config.substrate.modules.flake = {
    provides = [ "flake" "core:nix" ];
    generic =
      { lib, ... }:
      {
        options.hdwlinux.flake = lib.mkOption {
          description = "The path to the flake source directory.";
          type = lib.types.str;
          # Declared here rather than in a user module so hosts with no users
          # (minimal) still get a value for the host-scoped consumers.
          default = "/home/craig/Projects/hdwlinux/nix-config";
        };
      };

    homeManager =
      { config, lib, ... }:
      let
        flake = config.hdwlinux.flake;
      in
      {
        config = lib.mkIf (flake != null) {
          hdwlinux.programs.hdwlinux.subcommands.flake = {
            update = "nix flake update --flake ${flake} \"$@\"";
            "*" = "echo ${flake}";
          };
        };
      };
  };
}
