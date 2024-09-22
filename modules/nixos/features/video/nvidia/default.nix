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
        nvidiaPersistenced = true;
        nvidiaSettings = true;
        open = false;
        prime = {
          intelBusId = config.hdwlinux.features.video.intelBusId;
          nvidiaBusId = config.hdwlinux.features.video.nvidiaBusId;
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
        };
      };
    };
  };
}
