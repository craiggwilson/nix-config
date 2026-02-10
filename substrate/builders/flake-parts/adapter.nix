# Flake-parts adapter for substrate
# Provides core flake outputs and imports optional modules for nixos/home-manager
{
  config,
  inputs,
  ...
}:
let
  settings = config.substrate.settings;
  allOverlays = config.substrate.lib.mkAllOverlays;
in
{
  imports = [
    ./checks.nix
    ./home-manager.nix
    ./nixos.nix
    ./shells.nix
  ];

  systems = settings.systems;

  # Expose packages via perSystem (derivations only for flake output)
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = allOverlays;
        config.allowUnfree = true;
      };
    in
    {
      packages = config.substrate.lib.mkPackagesDerivationsOnly pkgs;
    };

  # Expose the packages overlay for external use
  flake.overlays.default = config.substrate.overlays;
}
