args:
let
  hasModuleArgs = args ? lib && args ? config;

  mkModule =
    {
      jail-nix ? null,
    }:
    {
      lib,
      config,
      inputs,
      ...
    }:
    let
      cfg = config.substrate.settings.jail;

      jailInput =
        if jail-nix != null then
          jail-nix
        else
          inputs.jail-nix
            or (throw "jail extension requires inputs.jail-nix or an explicit jail-nix argument");
    in
    {
      options.substrate.settings.jail = {
        basePermissions = lib.mkOption {
          type = lib.types.nullOr (lib.types.functionTo (lib.types.listOf lib.types.anything));
          description = ''
            Function that receives combinators and returns a list of base permissions.
            All jails inherit these permissions by default.
            Example: combinators: with combinators; [ base bind-nix-store-runtime-closure fake-passwd ]
          '';
          default = null;
        };

        additionalCombinators = lib.mkOption {
          type = lib.types.nullOr (lib.types.functionTo lib.types.attrs);
          description = ''
            Function that receives builtin combinators and returns an attrset of custom combinators.
            These are exposed under jail.combinators and in jail definitions.
            Example: builtinCombinators: with builtinCombinators; { my-permission = compose [ (readonly "/foo") ]; }
          '';
          default = null;
        };
      };

      config.substrate.settings.extraArgsGenerators = [
        (
          { pkgs, ... }:
          let
            extendArgs = {
              inherit pkgs;
            }
            // lib.optionalAttrs (cfg.basePermissions != null) {
              basePermissions = cfg.basePermissions;
            }
            // lib.optionalAttrs (cfg.additionalCombinators != null) {
              additionalCombinators = cfg.additionalCombinators;
            };
          in
          {
            jail = jailInput.lib.extend extendArgs;
          }
        )
      ];
    };
in
if hasModuleArgs then (mkModule { }) args else mkModule args
