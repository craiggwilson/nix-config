{
  config.substrate.modules.flake = {
    generic =
      { lib, ... }:
      {
        options.hdwlinux.flake = lib.mkOption {
          description = "The path to the flake source directory.";
          type = lib.types.nullOr lib.types.str;
          default = null;
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
