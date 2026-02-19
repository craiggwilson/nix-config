{ lib, config, ... }:
{
  options.substrate.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options =
            let
              parts = lib.match "([[:alnum:]]+)(@([[:alnum:]]*))?" name;
              name' = lib.elemAt parts 0;
              profile = lib.elemAt parts 2;
              profile' = if profile == null then "" else profile;
            in
            {
              name = lib.mkOption {
                description = "The name to use for the user account.";
                type = lib.types.str;
                default = name';
              };
              profile = lib.mkOption {
                description = "The profile of the user if one exists.";
                type = lib.types.str;
                default = profile';
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
