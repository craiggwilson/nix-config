{ lib, config, ... }@params:
{
  options = {
    systems.nixos = lib.mkOption {
      description = "NixOS systems to create.";
      type = lib.types.lazyAttrsOf (
        lib.types.submodule (
          { config, ... }:
          {
            options = {
              args = lib.mkOption {
                description = "Additional arguments to pass to system modules.";
                type = lib.types.attrs;
                default.value = { };
              };

              custom = {
                libs = lib.mkOption {
                  description = "Additional lib functions to use for the system.";
                  type = lib.types.listOf lib.types.raw;
                  default = params.config.custom.libs;
                };
                packages = lib.mkOption {
                  description = "Additional packages to use for the system.";
                  type = lib.types.listOf lib.types.raw;
                  default = params.config.custom.packages;
                };
              };

              modules = lib.mkOption {
                description = "A list of modules to use for the system.";
                type = lib.types.listOf lib.types.raw;
                default = [ ];
              };

              pkgs = lib.mkOption {
                description = "The Nixpkgs instance to use.";
                type = lib.types.raw;
                default =
                  if params.config.inputs ? nixpkgs && params.config.inputs.nixpkgs.result ? ${config.system} then
                    params.config.inputs.nixpkgs.result.${config.system}
                  else
                    null;
              };

              system = lib.mkOption {
                description = "The system to build for.";
                type = lib.types.enum [ "x86_64-linux" ];
                default = builtins.currentSystem;
              };

              result = lib.mkOption {
                description = "The created NixOS system.";
                type = lib.types.raw;
                readOnly = true;
                default = import "${config.pkgs.path}/nixos/lib/eval-config.nix" {
                  inherit (config) modules pkgs;
                  lib = lib.bootstrap.extendPkgsLib {
                    inherit (config) pkgs;
                    libs = config.custom.libs;
                  };
                  specialArgs = config.args;
                  modulesLocation = null;
                };
              };
            };
          }
        )
      );
      default = { };
    };
  };

  config = {
    assertions = lib.mapAttrsToList (name: value: {
      assertion = !(builtins.isNull value.pkgs);
      message = "A Nixpkgs instance is required for the NixOS system \"${name}\", but none was provided and \"inputs.nixpkgs\" does not exist.";
    }) config.systems.nixos;
  };
}
