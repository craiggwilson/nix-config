{
  config.substrate.modules.flake = {
    generic =
      { lib, ... }:
      {
        options.hdwlinux.flake = lib.mkOption {
          description = "The path to the flake source directory.";
          type = lib.types.str;
          # Declared here rather than in a user module so hosts with no users
          # (minimal) still get a value for the host-scoped consumers.
          # Lives in the user home; same on every machine.
          default = "/home/craig/Projects/github.com/craiggwilson/nix-config/default";
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
