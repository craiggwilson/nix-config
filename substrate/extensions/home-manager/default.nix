{ lib, config, ... }:
{
  options.substrate.settings = {
    homeManagerModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      description = "External home-manager modules to include in all home-manager configurations.";
      default = [ ];
    };
  };

  config.substrate.settings.supportedClasses = [ "homeManager" ];
}
