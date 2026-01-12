{ lib, ... }:
{
  options.substrate.types = lib.mkOption {
    type = lib.types.attrsOf (lib.types.functionTo lib.types.optionType);
    description = "Shared types that can be used across substrate modules. Takes a single argument 'lib' as an option.";
    default = { };
  };
}
