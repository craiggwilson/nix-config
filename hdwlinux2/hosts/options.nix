{
  config,
  lib,
  ...
}:

{
  options.hosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          system = lib.mkOption {
            type = lib.types.enum [
              "x86_64-linux"
            ];
            default = "x86_64-linux";
          };

          modules = lib.mkOption {
            type = lib.types.listOf lib.types.module;
            default = [ ];
          };

          users = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      }
    );
    default = { };
    description = "Host specific configurations.";
  };

  config.hosts = lib.mapAttrs (hostname: hostcfg: {
    ${hostname}.modules = [
      {
        networking = { inherit hostname; };
      }
    ];
  }) config.hosts;
}
