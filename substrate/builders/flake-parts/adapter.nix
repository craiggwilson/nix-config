# Flake-parts adapter for substrate
# Provides core flake outputs and calls registered output builders
{
  lib,
  config,
  inputs,
  ...
}:
let
  settings = config.substrate.settings;
  outputs = config.substrate.outputs;

  # All overlays come from settings.overlays (extensions add theirs there too)
  allOverlays = settings.overlays or [ ];

  # Separate outputs by type (check first builder in each list for type)
  # Exclude overlays from globalOutputs since they're handled specially
  perSystemOutputs = lib.filterAttrs (
    _: builders: builders != [ ] && (builtins.head builders).type == "per-system"
  ) outputs;
  globalOutputs = lib.filterAttrs (
    name: builders: name != "overlays" && builders != [ ] && (builtins.head builders).type == "global"
  ) outputs;

  # Build all builders for an output and merge results
  buildAndMerge =
    builderArgs: builders: lib.foldl' (acc: builder: acc // (builder.build builderArgs)) { } builders;
in
{
  imports = [
    ./checks.nix
  ];

  systems = settings.systems;

  # Build per-system outputs
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = allOverlays;
      };
      builderArgs = {
        inherit pkgs system inputs;
        substrate = config.substrate;
      };
    in
    lib.mapAttrs (_: builders: buildAndMerge builderArgs builders) perSystemOutputs;

  # Build global outputs
  flake =
    let
      builderArgs = {
        inherit inputs;
        substrate = config.substrate;
      };
      # Build non-overlay global outputs
      globalResults = lib.mapAttrs (_: builders: buildAndMerge builderArgs builders) globalOutputs;
      # Build overlay output by collecting all named overlays
      overlayResults =
        if outputs ? overlays && outputs.overlays != [ ] then
          {
            overlays = buildAndMerge builderArgs outputs.overlays;
          }
        else
          { };
    in
    globalResults // overlayResults;
}
