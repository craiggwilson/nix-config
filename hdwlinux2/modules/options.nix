{ lib, moduleLocation, ... }:
let
  inherit (lib)
    mapAttrs
    mkOption
    types
    ;
  inherit (lib.strings)
    escapeNixIdentifier
    ;

  addInfo =
    class: moduleName:
    if class == "generic" then
      module: module
    else
      module:
      # By returning a function, it will be accepted as a full-on module despite
      # a submodule having shorthandOnlyDefinesConfig = true, which is the
      # `types.submodule` default.
      # https://github.com/hercules-ci/flake-parts/issues/326
      { ... }:
      {
        # TODO: set key?
        _class = class;
        _file = "${toString moduleLocation}#modules.${escapeNixIdentifier class}.${escapeNixIdentifier moduleName}";
        imports = [ module ];
      };
in
{
  options.modules = mkOption {
    type = types.lazyAttrsOf (types.lazyAttrsOf types.deferredModule);
    apply = mapAttrs (k: mapAttrs (addInfo k));
  };
}
