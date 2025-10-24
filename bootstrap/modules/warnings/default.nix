{ lib, ... }:
{
  options = {
    warnings = lib.mkOption {
      description = "A list of warnings to display after evaluating modules.";
      default = [ ];
      type = lib.types.listOf lib.types.str;
    };
  };
}
