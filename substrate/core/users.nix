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
