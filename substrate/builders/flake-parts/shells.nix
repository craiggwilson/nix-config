{
  lib,
  config,
  inputs,
  ...
}:
let
  settings = config.substrate.settings;
  slib = config.substrate.lib;
  allOverlays = slib.mkAllOverlays;
  hasShells = (settings.shells or [ ]) != [ ];

  mkShells =
    pkgs:
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
  perSystem =
    { system, ... }:
    lib.mkIf hasShells (
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = allOverlays;
          config.allowUnfree = true;
        };
      in
      {
        devShells = mkShells pkgs;
      }
    );
}

