{ lib, config, ... }:
{
  options.substrate.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            name = lib.mkOption {
              description = "The name to use for the user account.";
              type = lib.types.str;
              default = name;
            };
            system = lib.mkOption {
              type = lib.types.enum config.substrate.settings.systems;
              default = builtins.currentSystem;
            };
          };
        }
      )
    );
    default = { };
    description = "User specific configurations.";
  };
}
