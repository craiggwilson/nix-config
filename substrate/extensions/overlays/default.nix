{ lib, ... }:
{
  options.substrate.settings.overlays = lib.mkOption {
    type = lib.types.listOf (lib.types.functionTo (lib.types.functionTo lib.types.attrs));
    description = ''
      Additional overlays to apply to nixpkgs when building configurations.
      Each overlay should be a function: final: prev: { ... }
      These are for internal use only and are not exposed in flake outputs.
    '';
    default = [ ];
  };
}
