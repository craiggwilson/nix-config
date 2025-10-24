{ lib, ... }:
{
  options = {
    pins = lib.mkOption {
      description = "A list of pins to use for the flake.";
      default = { };
      type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.path);
    };
  };
}
