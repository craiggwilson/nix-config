{
  lib,
  ...
}:
{
  options.hdwlinux.monitors = {
    profiles = lib.mkOption {
      description = "The set of profiles to use.";
      type = lib.types.listOf (lib.types.str);
      default = [ ];
    };
    monitors = lib.mkOption {
      description = "Options to set the monitor configuration.";
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            port = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            description = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            width = lib.mkOption { type = lib.types.int; };
            height = lib.mkOption { type = lib.types.int; };
            x = lib.mkOption { type = lib.types.int; };
            y = lib.mkOption { type = lib.types.int; };
            scale = lib.mkOption { type = lib.types.float; };
            workspace = lib.mkOption { type = lib.types.str; };
            displaylink = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            profiles = lib.mkOption {
              type = lib.types.attrsOf (lib.types.nullOr (lib.types.bool));
            };
          };
        }
      );
    };
  };
}
