{
  lib,
  config,
  ...
}:

{
  options.substrate.hosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            name = lib.mkOption {
              description = "The hostname of the machine.";
              type = lib.types.str;
              default = name;
            };
            system = lib.mkOption {
              type = lib.types.enum config.substrate.settings.systems;
              default = builtins.currentSystem;
            };
            users = lib.mkOption {
              type = lib.types.listOf (lib.types.enum (builtins.attrNames config.substrate.users));
              default = [ ];
            };
            nixpkgsConfig = lib.mkOption {
              type = lib.types.attrs;
              description = ''
                Additional nixpkgs config to apply when instantiating nixpkgs for this host.
                This is merged with the default config (allowUnfree = true).
                Useful for options that must be set at nixpkgs instantiation time,
                such as cudaSupport.

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
    description = "Host specific configurations.";
  };
}
