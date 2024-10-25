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
      ];
    };

    hardware = {
      nvidia = {
        modesetting.enable = true;
        nvidiaPersistenced = true;
        nvidiaSettings = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        open = false;
        prime = {
          sync.enable = true;
          intelBusId = config.hdwlinux.features.video.intelBusId;
          nvidiaBusId = config.hdwlinux.features.video.nvidiaBusId;
          # offload = {
          #   enable = true;
          #   enableOffloadCmd = true;
          # };
        };
      };
    };
  };
}
