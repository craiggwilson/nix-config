# Evaluate the "perUser" class modules for one (host, user) pair into the
# schema config. Mirrors how the substrate home-manager extension builds its
# per-user evaluation, minus home-manager itself.
#
# The evalModules `lib` argument is pinned to nixpkgs' own lib, so our helpers
# are merged by intercepting function modules and re-applying them with
# `args.lib` replaced (attrset shorthand modules have no args to rewrite).
{
  lib,
  inputs,
  slib,
  hostcfg,
  usercfg,
  allOverlays,
}:
let
  pkgs = import inputs.nixpkgs {
    localSystem = usercfg.system;
    overlays = allOverlays;
  };

  extraArgs = slib.extraArgsGenerator {
    inherit
      hostcfg
      usercfg
      inputs
      ;
  };

  fullLib = lib // import ./lib.nix {
    inherit
      lib
      pkgs
      ;
  };

  # The class option (deferredModule) stores its definitions wrapped as
  # { imports = [ ... ]; }, so function modules are found recursively inside
  # `imports`, not at the top level.
  wrapModule =
    m:
    if builtins.isFunction m then
      args: m (args // { lib = fullLib; })
    else if builtins.isAttrs m && m ? imports then
      m
      // {
        imports = map wrapModule m.imports;
      }
    else
      m;
in
(
  lib.evalModules {
    modules = [ ./schema.nix ] ++ map wrapModule (slib.findModulesForClass "perUser" [
      hostcfg
      usercfg
    ]);
    specialArgs = extraArgs // {
      inherit
        pkgs
        inputs
        hostcfg
        usercfg
        ;
    };
  }
).config
