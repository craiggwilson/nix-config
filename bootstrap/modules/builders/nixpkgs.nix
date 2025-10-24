{ lib, config, ... }:
let
  inherit (config) inputs;
in
{
  config = {
    builders.nixpkgs = {
      settings = {
        type = lib.types.submodule {
          options = {
            pkgs = lib.mkOption {
              description = "The Nixpkgs instance to use to build the package.";
              type = lib.types.raw;
              default = inputs.nixpkgs.result or null;
            };

            args = lib.mkOption {
              description = "Arguments to pass to the builder.";
              type = lib.types.anything;
              default = { };
            };
          };
        };

        default = { };
      };

      build =
        package:
        if builtins.isNull package.settings.pkgs then
          builtins.throw "No package set provided for package \"${package.name}\"."
        else
          lib.genAttrs package.systems (
            system:
            let
              pkgs = package.settings.pkgs.${system};
            in
            if !(package.settings.pkgs ? ${system}) then
              builtins.throw "No package set for system \"${system}\" provided for package \"${package.name}\"."
            else
              pkgs.callPackage package.package package.settings.args
          );
    };
  };
}
