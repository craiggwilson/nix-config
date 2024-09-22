{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.features.video.nvidia;
in
{

  options.hdwlinux.features.video.nvidia = {
    enable = lib.hdwlinux.mkEnableOpt [ "video:nvidia" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    services = {
      xserver.videoDrivers = [
        "nvidia"
        "modesetting"
      ];
    };

    hardware = {
      nvidia = {
        modesetting.enable = true;
        nvidiaPersistenced = false;
        nvidiaSettings = true;
        open = false;
        prime = {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
        };
      };
    };
  };
}
