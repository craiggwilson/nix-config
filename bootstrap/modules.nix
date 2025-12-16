# Flake-parts module for NixOS and Home Manager modules.
# Exposes modules from configured lists.
{ lib, config, ... }:
let
  # Helper to build module attrset from paths
  buildModuleAttrs =
    modulePaths:
    (lib.listToAttrs (
      map (path: {
        name = baseNameOf path;
        value = import path;
      }) modulePaths
    ))
    // {
      default =
        { ... }:
        {
          imports = map (path: import path) modulePaths;
        };
    };
in
{
  flake = {
    nixosModules = buildModuleAttrs config.project.nixosModules;
    homeModules = buildModuleAttrs config.project.homeModules;
  };
}
