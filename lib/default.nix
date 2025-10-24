{ lib }:
{
  # Recursively find all default.nix files in subdirectories
  # Used for auto-discovering modules in a directory tree
  findModules =
    dir:
    let
      entries = builtins.readDir dir;
      subdirs = lib.filterAttrs (name: type: type == "directory") entries;

      # For each subdirectory, check if it has a default.nix
      moduleFiles = lib.mapAttrsToList (
        name: _:
        let
          modulePath = dir + "/${name}/default.nix";
        in
        if builtins.pathExists modulePath then
          [ modulePath ] ++ lib.hdwlinux.findModules (dir + "/${name}")
        else
          lib.hdwlinux.findModules (dir + "/${name}")
      ) subdirs;
    in
    lib.flatten moduleFiles;

  # Load all overlays from a directory
  # Each overlay should be in a subdirectory with a default.nix
  loadOverlays =
    dir:
    let
      overlayDirs = builtins.readDir dir;
      overlayNames = builtins.filter (name: overlayDirs.${name} == "directory") (
        builtins.attrNames overlayDirs
      );
    in
    builtins.map (
      name:
      let
        overlayPath = dir + "/${name}/default.nix";
        overlayModule = import overlayPath;
        # All overlays in this repo follow the pattern: { args... }: final: prev: { ... }
        # So we always call the module with args to get the actual overlay function
        overlayFn = overlayModule {
          inherit lib;
          channels = { };
        };
      in
      overlayFn
    ) overlayNames;

  # Load all packages from a directory
  # Returns an attrset of package names to package derivations
  loadPackages =
    pkgs: dir:
    let
      packageDirs = builtins.readDir dir;
      packageNames = builtins.filter (name: packageDirs.${name} == "directory") (
        builtins.attrNames packageDirs
      );
    in
    builtins.listToAttrs (
      builtins.map (name: {
        inherit name;
        value = pkgs.callPackage (dir + "/${name}") { };
      }) packageNames
    );

  # Load all shells from a directory
  # Returns an attrset of shell names to shell derivations
  loadShells =
    pkgs: inputs: dir:
    let
      shellDirs = builtins.readDir dir;
      shellNames = builtins.filter (name: shellDirs.${name} == "directory") (
        builtins.attrNames shellDirs
      );
    in
    builtins.listToAttrs (
      builtins.map (name: {
        inherit name;
        value = pkgs.callPackage (dir + "/${name}") {
          inherit inputs lib;
        };
      }) shellNames
    );

  # Load all system configurations from a directory
  # Returns an attrset of system names to NixOS configurations
  loadSystems =
    mkNixosConfiguration: system: dir:
    let
      systemDirs = builtins.readDir dir;
      systemNames = builtins.filter (name: systemDirs.${name} == "directory") (
        builtins.attrNames systemDirs
      );
    in
    builtins.listToAttrs (
      builtins.map (name: {
        inherit name;
        value = mkNixosConfiguration system name (dir + "/${name}");
      }) systemNames
    );

  # Load all home configurations from a directory
  # Returns an attrset of home names to Home Manager configurations
  loadHomes =
    mkHomeConfiguration: system: dir:
    let
      homeDirs = builtins.readDir dir;
      homeNames = builtins.filter (name: homeDirs.${name} == "directory") (
        builtins.attrNames homeDirs
      );
    in
    builtins.listToAttrs (
      builtins.map (name: {
        inherit name;
        value = mkHomeConfiguration system name (dir + "/${name}");
      }) homeNames
    );
}

