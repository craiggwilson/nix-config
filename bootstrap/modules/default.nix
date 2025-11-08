{ lib, ... }:
{

  options = {
    assertions = lib.mkOption {
      description = "A list of assertions to check against in order for the evaluation to succeed.";
      default.value = [ ];
      type = lib.types.listOf (
        lib.types.submoduleWith {
          shorthandOnlyDefinesConfig = true;
          modules = [
            {
              options = {
                assertion = lib.mkOption {
                  description = "The assertion to check against.";
                  type = lib.types.bool;
                };

                message = lib.mkOption {
                  description = "The message to display if the assertion fails.";
                  type = lib.types.string;
                };
              };
            }
          ];
        }
      );
    };

    extraLibs = lib.mkOption {
      description = "Custom libraries to load.";
      type = lib.types.listOf lib.types.raw;
      default = [ ];
    };

    overlays = lib.mkOption {
      description = "A list of overlays to apply to the nixpkgs instance.";
      type = lib.types.listOf lib.types.raw;
      default = [ ];
    };

    pins = lib.mkOption {
      description = "A list of pins to use for the flake.";
      default = { };
      type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.path);
    };

    warnings = lib.mkOption {
      description = "A list of warnings to display after evaluating modules.";
      default = [ ];
      type = lib.types.listOf lib.types.str;
    };
  };

}
