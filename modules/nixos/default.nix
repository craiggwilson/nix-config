{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux;
in
{
  options.hdwlinux = {
    video = lib.mkOption {
      description = "Options to set the video configuration.";
      type = lib.types.submodule {
        options = {
          intel = lib.mkOption {
            description = "The intel video card information.";
            type = lib.hdwlinux.pcicard;
          };
          nvidia = lib.mkOption {
            description = "The nvidia video card information.";
            type = lib.hdwlinux.pcicard;
          };
        };
      };
    };
  };

  config.home-manager.sharedModules = lib.mkIf config.hdwlinux.home-manager.enable [
    {
      hdwlinux.video = cfg.video;
    }
  ];
}
