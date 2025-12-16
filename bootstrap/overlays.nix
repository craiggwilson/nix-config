# Flake-parts module for overlays.
# Sets up the project overlay and external overlays.
{
  inputs,
  lib,
  config,
  ...
}:
let
  # Import custom overlays from paths
  customOverlays = map (p: import p { inherit lib; }) config.project.overlays;

  # Overlay that adds project packages to pkgs (optionally under a namespace)
  projectPackagesOverlay =
    final: prev:
    let
      packagesConfig = config.project.packages;
      # Handle both list and attrset with paths/namespace
      isNamespaced = builtins.isAttrs packagesConfig;
      paths = if isNamespaced then packagesConfig.paths else packagesConfig;
      namespace = if isNamespaced then packagesConfig.namespace else null;

      packages = lib.listToAttrs (
        map (path: {
          name = baseNameOf path;
          value = final.callPackage path { };
        }) paths
      );
    in
    if namespace != null then { ${namespace} = (prev.${namespace} or { }) // packages; } else packages;

  # Overlay that merges project lib extensions into lib
  # The project lib should provide its own namespace (e.g., { hdwlinux = { ... }; })
  projectLibOverlay = final: prev: {
    lib = prev.lib // config.project.lib;
  };

  # Overlay for stable packages
  stableOverlay = final: prev: {
    stable = import inputs.nixpkgs-stable {
      system = prev.system;
      config.allowUnfree = true;
    };
  };
in
{
  flake = {
    overlays = {
      default = lib.composeManyExtensions (
        config.project.external.overlays
        ++ [
          stableOverlay
          projectLibOverlay
          projectPackagesOverlay
        ]
        ++ customOverlays
      );

      project = lib.composeManyExtensions (
        [
          projectLibOverlay
          projectPackagesOverlay
        ]
        ++ customOverlays
      );
    };
  };
}
