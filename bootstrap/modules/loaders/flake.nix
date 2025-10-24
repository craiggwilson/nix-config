{ lib, config, ... }:
let
  compat = config.inputs.flake-compat.result;
in
{
  config = {
    loaders.flake = {
      settings = {
        type = lib.types.submodule {
          options = {
            target = lib.mkOption {
              description = "The relative path of the file to load.";
              type = lib.types.str;
              default = "flake.nix";
            };

            inputs = lib.mkOption {
              description = "The inputs to replace in the loaded flake.";
              type = lib.types.attrsOf lib.types.raw;
              default = { };
            };
          };
        };
        default = { };
      };

      load =
        input:
        let
          value = compat.load {
            src = builtins.dirOf "${input.src}/${input.settings.target}";
            replacements = input.settings.inputs;
          };
        in
        value;
    };
  };
}
