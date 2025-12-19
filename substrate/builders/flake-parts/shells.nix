{
  lib,
  config,
  inputs,
  ...
}:
let
  settings = config.substrate.settings;
  allOverlays = config.substrate.lib.mkAllOverlays;
  hasShells = (settings.shells or [ ]) != [ ];

  shellNameFromPath =
    path:
    let
      basename = baseNameOf path;
    in
    lib.removeSuffix ".nix" basename;

  mkShells =
    pkgs:
    lib.listToAttrs (
      map (path: {
        name = shellNameFromPath path;
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

