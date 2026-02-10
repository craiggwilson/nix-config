{ lib, config, ... }:
let
  settings = config.substrate.settings;

  # Extracts a name from a path by taking the basename and removing .nix suffix.
  # Works for both files (foo.nix -> foo) and directories (foo/ -> foo).
  nameFromPath =
    path:
    let
      basename = baseNameOf path;
    in
    lib.removeSuffix ".nix" basename;

  mkPackages =
    pkgs:
    lib.listToAttrs (
      lib.map (path: {
        name = nameFromPath path;
        value = import path { inherit lib pkgs; };
      }) settings.packages
    );

  mkPackagesDerivationsOnly = pkgs: lib.filterAttrs (_: v: lib.isDerivation v) (mkPackages pkgs);

  mkAllOverlays = [ config.substrate.overlays ] ++ settings.overlays;

  unique = list: lib.foldl' (acc: x: if lib.elem x acc then acc else acc ++ [ x ]) [ ] list;

  extractClassModules =
    class: mods:
    let
      extractClass =
        c: lib.flatten (lib.map (m: if m ? ${c} && m.${c} != null then [ m.${c} ] else [ ]) mods);
      classModules = extractClass class;
      genericModules = if class != "generic" then extractClass "generic" else [ ];
    in
    genericModules ++ classModules;

  extraArgsGenerator =
    {
      hostcfg,
      usercfg,
      pkgs,
      inputs,
    }:
    lib.mergeAttrsList (
      lib.map (
        f:
        f {
          inherit
            hostcfg
            usercfg
            pkgs
            inputs
            ;
        }
      ) settings.extraArgsGenerators
    );

  hasClass = class: builtins.elem class settings.supportedClasses;
in
{
  options.substrate.lib = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    description = ''
      Library functions for use by builders, extensions, and other substrate components.
    '';
    readOnly = true;
    default = {
      inherit
        nameFromPath
        mkPackages
        mkPackagesDerivationsOnly
        mkAllOverlays
        unique
        extractClassModules
        extraArgsGenerator
        hasClass
        ;
    };
  };
}
