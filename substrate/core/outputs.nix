{ lib, ... }:
let
  builderType = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lib.types.enum [
          "per-system"
          "global"
        ];
        description = ''
          The type of output:
          - "per-system": Output is generated per system (receives { pkgs, system, inputs, substrate })
          - "global": Output is generated once globally (receives { inputs, substrate })
        '';
      };
      build = lib.mkOption {
        type = lib.types.functionTo lib.types.unspecified;
        description = ''
          Function to build the output.
          For "per-system": receives { pkgs, system, inputs, substrate }
          For "global": receives { inputs, substrate }
        '';
      };
    };
  };
in
{
  options.substrate.outputs = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf builderType);
    description = ''
      Generic output declarations for the flake.
      Each output name maps to a list of builders, allowing multiple extensions
      to contribute to the same output. All builders for an output must have
      the same type (per-system or global).
    '';
    default = { };
  };
}
