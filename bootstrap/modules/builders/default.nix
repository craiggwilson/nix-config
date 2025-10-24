{ lib, ... }:
{
  options = {
    builders = lib.mkOption {
      description = "Builders for different types of outputs.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            settings = {
              type = lib.mkOption {
                description = "The type of the settings attr passed to the builder.";
                type = lib.types.optionType;
              };
            };
            default = lib.mkOption {
              description = "Default settings for the builder.";
              type = lib.types.raw; # TODO: make lib.types.type an actual thing...
            };

            build = lib.mkOption {
              description = "Function to build the output.";
              type = lib.types.functionTo lib.types.raw;
            };
          };
        }
      );
      default = { };
    };
  };
}
