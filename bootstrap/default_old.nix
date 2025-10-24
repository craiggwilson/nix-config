# { pins }:
# let
#   create = config: let 
#     basePkgs = import pins.nixpkgs-unstable { inherit (config) system; };
#     loaders = import ./lib/loaders.nix { inherit pins; lib = basePkgs.lib;};
#     inputs = import ./lib/inputs.nix { inherit loaders; };
#     overlays = import ./lib/overlays.nix { };

#     modules = inputs.load config.inputs;
#     in 
#     {
      
#     };

#   overlays = {
#     combine =
#       overlays:
#       builtins.foldl' (
#         acc: overlay: final: prev:
#         (acc final prev) // (overlay final prev)
#       ) (final: prev: { }) overlays;

#     load =
#       lib: dir:
#       let
#         overlayDirs = builtins.readDir dir;
#         overlayNames = builtins.filter (name: overlayDirs.${name} == "directory") (
#           builtins.attrNames overlayDirs
#         );
#       in
#       builtins.listToAttrs (builtins.map (
#         name:
#         let
#           overlayPath = dir + "/${name}/default.nix";
#           overlayModule = import overlayPath;
#           overlayFn = overlayModule {
#             inherit lib;
#           };
#         in
#         {
#           inherit name;
#           value = overlayFn;
#         }
#       )) overlayNames;
#   };

#   # Create a nixpkgs instance with config and overlays
#   mkPkgs =
#     nixpkgs: system: config: overlays:
#     import nixpkgs {
#       inherit system config overlays;
#     };

#   # Create per-system outputs
#   # Takes a function that receives system and returns an attrset of outputs
#   forAllSystems =
#     systems: fn:
#     builtins.listToAttrs (
#       builtins.map (system: {
#         name = system;
#         value = fn system;
#       }) systems
#     );

#   # Extract a specific attribute from per-system outputs
#   # e.g., extractPerSystem "packages" perSystemOutputs
#   extractPerSystem = attr: perSystemOutputs: builtins.mapAttrs (_: v: v.${attr}) perSystemOutputs;

#   # Load all packages from a directory
#   # Returns an attrset of package names to package derivations
#   loadPackages =
#     pkgs: dir:
#     let
#       packageDirs = builtins.readDir dir;
#       packageNames = builtins.filter (name: packageDirs.${name} == "directory") (
#         builtins.attrNames packageDirs
#       );
#     in
#     builtins.listToAttrs (
#       builtins.map (name: {
#         inherit name;
#         value = pkgs.callPackage (dir + "/${name}") { };
#       }) packageNames
#     );

#   # Load all shells from a directory
#   # Returns an attrset of shell names to shell derivations
#   loadShells =
#     {
#       lib,
#       pkgs,
#       inputs,
#       dir,
#     }:
#     let
#       shellDirs = builtins.readDir dir;
#       shellNames = builtins.filter (name: shellDirs.${name} == "directory") (
#         builtins.attrNames shellDirs
#       );
#     in
#     builtins.listToAttrs (
#       builtins.map (name: {
#         inherit name;
#         value = pkgs.callPackage (dir + "/${name}") {
#           inherit inputs lib;
#         };
#       }) shellNames
#     );

#   # Load all system configurations from a directory
#   # Returns an attrset of system names to NixOS configurations
#   loadSystems =
#     mkNixosConfiguration: system: dir:
#     let
#       systemDirs = builtins.readDir dir;
#       systemNames = builtins.filter (name: systemDirs.${name} == "directory") (
#         builtins.attrNames systemDirs
#       );
#     in
#     builtins.listToAttrs (
#       builtins.map (name: {
#         inherit name;
#         value = mkNixosConfiguration system name (dir + "/${name}");
#       }) systemNames
#     );

#   # Load all home configurations from a directory
#   # Returns an attrset of home names to Home Manager configurations
#   loadHomes =
#     mkHomeConfiguration: system: dir:
#     let
#       homeDirs = builtins.readDir dir;
#       homeNames = builtins.filter (name: homeDirs.${name} == "directory") (builtins.attrNames homeDirs);
#     in
#     builtins.listToAttrs (
#       builtins.map (name: {
#         inherit name;
#         value = mkHomeConfiguration system name (dir + "/${name}");
#       }) homeNames
#     );
# }
