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
            nixpkgsConfig = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              description = ''
                Additional nixpkgs config to apply when instantiating nixpkgs for this user
                (standalone home-manager only). This is merged with the default config
                (allowUnfree = true). For NixOS-managed home-manager, the host's nixpkgsConfig
                is used instead.

                Example:
                  nixpkgsConfig = { cudaSupport = true; };
              '';
              default = { };
            };
          };
        }
      )
    );
    default = { };
    description = "User specific configurations.";
  };
}
