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
  };
}
