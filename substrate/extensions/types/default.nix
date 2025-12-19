{ lib, ... }:
{
  options.substrate.types = lib.mkOption {
    type = lib.types.attrsOf lib.types.optionType;
    description = "Shared types that can be used across substrate modules.";
    default = { };
  };
}

