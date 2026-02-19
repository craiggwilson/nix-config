{ lib, config, ... }:
let
  settings = config.substrate.settings;
  slib = config.substrate.lib;

  mkShells =
    { pkgs, inputs }:
    lib.listToAttrs (
      lib.map (path: {
        name = slib.nameFromPath path;
        value = import path {
          inherit lib inputs pkgs;
          inherit (pkgs) stdenv;
        };
      }) settings.shells
    );
in
{
  options.substrate.settings = {
    shells = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = "List of paths to shell definitions (nix files that return a function taking pkgs and returning a derivation).";
      default = [ ];
    };
  };

  config.substrate.outputs.devShells = lib.mkIf (settings.shells != [ ]) [
    {
      type = "per-system";
      build = { pkgs, inputs, ... }: mkShells { inherit pkgs inputs; };
    }
  ];
}
