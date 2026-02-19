{ lib, config, ... }:
let
  settings = config.substrate.settings;
  moduleFinders = config.substrate.moduleFinders;

  # Extracts a name from a path by taking the basename and removing .nix suffix.
  # Works for both files (foo.nix -> foo) and directories (foo/ -> foo).
  nameFromPath =
    path:
    let
      basename = baseNameOf path;
    in
    lib.removeSuffix ".nix" basename;

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

  # Find modules for a given class using the configured modules finder.
  # Takes a class name and a list of configs (e.g., [hostcfg], [hostcfg usercfg], [usercfg]).
  # Returns the extracted modules for that class.
  findModulesForClass =
    class: configs:
    let
      finder = moduleFinders.${settings.modulesFinder};
      mods = finder.find configs;
    in
    extractClassModules class mods;

  extraArgsGenerator =
    {
      hostcfg,
      usercfg,
      inputs,
    }:
    lib.mergeAttrsList (
      lib.map (
        f:
        f {
          inherit
            hostcfg
            usercfg
            inputs
            ;
        }
      ) settings.extraArgsGenerators
    );

  hasClass = class: builtins.elem class settings.supportedClasses;
in
{
  options.substrate.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.anything;
    description = ''
      Library functions for use by builders, extensions, and other substrate components.
      Extensions can add functions by setting config.substrate.lib.<name> = <function>.
    '';
  };

  config.substrate.lib = {
    inherit
      nameFromPath
      unique
      findModulesForClass
      extraArgsGenerator
      hasClass
      ;
  };
}
