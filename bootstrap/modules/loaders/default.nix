{ lib, ... }:
{
  options = {
    loaders = lib.mkOption {
      description = "Handlers for different types of inputs.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            settings = {
              description = "Function to load the input.";
              type = lib.mkOption {
                description = "The type of the settings attr passed to the loader.";
                type = lib.types.optionType;
              };
              default = lib.mkOption {
                description = "Default settings for the loader.";
                # TODO: make lib.types.type an actual thing...
                type = lib.types.anything;
              };
            };

            check = lib.mkOption {
              description = "Function to check if the input is valid.";
              type = lib.types.functionTo lib.types.bool;
              default = _: false;
            };

            load = lib.mkOption {
              description = "Function to load the input.";
              type = lib.types.functionTo lib.types.raw;
            };
          };

        }
      );
      default = { };
    };
  };
}
