{ lib, config, ... }:
{
  options = {
    systems.nixos = lib.mkOption {
      description = "NixOS systems to create.";
      type = lib.types.lazyAttrsOf (
        lib.types.submodule (args: {
          options = {
            modules = lib.mkOption {
              description = "A list of modules to use for the system.";
              type = lib.types.listOf lib.types.raw;
              default = [ ];
            };
            pkgs = lib.mkOption {
              description = "The Nixpkgs instance to use.";
              type = lib.types.raw;
              default =
                if config.inputs ? nixpkgs && config.inputs.nixpkgs.result ? ${args.config.system} then
                  config.inputs.nixpkgs.result.${args.config.system}
                else
                  null;
            };
            specialArgs = lib.mkOption {
              description = "Additional arguments to pass to system modules.";
              type = lib.types.attrsOf lib.types.anything;
              default.value = { };
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
              default =
                let
                  pkgs = args.config.pkgs;
                in
                import "${pkgs.path}/nixos/lib/eval-config.nix" {
                  inherit pkgs;
                  inherit (args.config) modules specialArgs;
                  lib = lib.bootstrap.extendPkgsLib {
                    inherit pkgs;
                    libs = config.extraLibs;
                  };
                  modulesLocation = null;
                };
            };
          };
        })
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
