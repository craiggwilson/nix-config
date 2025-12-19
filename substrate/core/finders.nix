{ lib, ... }:
let
  finderType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "The name of the finder.";
          default = name;
        };
        find = lib.mkOption {
          type = lib.types.functionTo lib.types.raw;
          description = ''
            A function that takes a list of configs (e.g., [hostcfg usercfg]) and returns
            the applicable substrate modules. The finder is responsible for merging/combining
            the configs as appropriate for its matching strategy.

            Examples:
              - finder.find [hostcfg] - find modules for host only
              - finder.find [hostcfg usercfg] - find modules for combined host+user context
              - finder.find [usercfg] - find modules for user only (standalone home-manager)
          '';
        };
      };
    }
  );
in
{
  options.substrate.finders = lib.mkOption {
    type = lib.types.attrsOf finderType;
    description = "All the registered finders.";
    default = { };
  };
}
