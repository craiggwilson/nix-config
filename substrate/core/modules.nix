{ lib, config, ... }:
let
  settings = config.substrate.settings;

  reservedNames = settings.supportedClasses ++ lib.attrNames settings.extraModuleOptions;

  treeType = lib.types.submodule {
    options =
      lib.genAttrs settings.supportedClasses (
        _:
        lib.mkOption {
          type = lib.types.nullOr lib.types.deferredModule;
          default = null;
        }
      )
      // settings.extraModuleOptions;
    freeformType = lib.types.lazyAttrsOf treeType;
  };

  hasSubstrateContent =
    module:
    builtins.any (class: module ? ${class} && module.${class} != null) settings.supportedClasses;

  collectSubstrateModules =
    module:
    let
      childAttrs = lib.filterAttrs (n: v: (!builtins.elem n reservedNames) && builtins.isAttrs v) module;
      childModules = lib.flatten (
        lib.mapAttrsToList (_: child: collectSubstrateModules child) childAttrs
      );
    in
    if hasSubstrateContent module then [ module ] ++ childModules else childModules;
in
{
  options.substrate = {
    modules = lib.mkOption {
      description = "Modules available for inclusion in user and host configurations. Structure: substrate.modules.<path>.<to>.<module>";
      type = lib.types.submodule { freeformType = lib.types.lazyAttrsOf treeType; };
      default = { };
    };
    settings = {
      extraModuleOptions = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        description = "Additional typed options to recognize at each level of the module tree. The key is the attribute name, the value is the type.";
        default = { };
      };

      nixosModules = lib.mkOption {
        type = lib.types.listOf lib.types.deferredModule;
        description = "External NixOS modules to include in all NixOS configurations.";
        default = [ ];
      };
    };
  };

  # The "all" finder returns all modules regardless of the configs passed
  config.substrate.finders.all = {
    find = _cfgs: collectSubstrateModules config.substrate.modules;
  };
}
