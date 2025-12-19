{ lib, config, ... }:
let
  settings = config.substrate.settings;

  packageNameFromPath =
    path:
    let
      basename = baseNameOf path;
    in
    lib.removeSuffix ".nix" basename;

  mkPackages =
    pkgs:
    lib.listToAttrs (
      map (path: {
        name = packageNameFromPath path;
        value = import path { inherit lib pkgs; };
      }) settings.packages
    );

  mkPackagesDerivationsOnly = pkgs: lib.filterAttrs (_: v: lib.isDerivation v) (mkPackages pkgs);

  mkAllOverlays = [ config.substrate.overlays ] ++ settings.overlays;

  unique = list: lib.foldl' (acc: x: if lib.elem x acc then acc else acc ++ [ x ]) [ ] list;

  extractClassModules =
    class: mods:
    lib.flatten (lib.map (m: if m ? ${class} && m.${class} != null then [ m.${class} ] else [ ]) mods);

  extraArgsGenerator =
    { hostcfg, usercfg }:
    lib.mergeAttrsList (builtins.map (f: f { inherit hostcfg usercfg; }) settings.extraArgsGenerators);

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
