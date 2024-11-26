{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux;
in
{
  options.hdwlinux = {
    tags = lib.mkOption {
      description = "Tags used to enable components in the system.";
      type = lib.hdwlinux.types.allTags;
    };
  };

  config = {
    lib.hdwlinux = {
      mkEnableOption =
        name: default:
        lib.mkOption {
          description = "Whether to enable ${name}";
          type = lib.types.bool;
          default =
            if builtins.isBool default then
              default
            else if builtins.isString default then
              lib.hdwlinux.elemPrefix default cfg.tags
            else if builtins.isList default then
              lib.hdwlinux.matchTags default cfg.tags
            else
              throw "Only bool, string, or list of strings are supported";
        };
    };

    # lib.hdwlinux = {
    #   mkEnableOption2 =
    #     name: default:
    #     lib.mkOption {
    #       description = "Whether to enable ${name}";
    #       type = lib.hdwlinux.enable cfg.tags;
    #       default = default;
    #       #     if builtins.isBool arg then
    #       #       arg
    #       #     else if builtins.isString arg then
    #       #       lib.hdwlinux.elemPrefix arg cfg.tags
    #       #     else if builtins.isList arg then
    #       #       lib.hdwlinux.matchTags arg cfg.tags
    #       #     else
    #       #       throw "Only bool, string, or list of strings are supported";
    #     };
    # };

    home-manager.sharedModules = [ { hdwlinux.tags = cfg.tags; } ];
  };
}
