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
        open = false;
        powerManagement = {
          enable = true;
          finegrained = true;
        };
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

    boot = {
      blacklistedKernelModules = [ "nouveau" ];

      extraModprobeConfig =
        "options nvidia "
        + lib.concatStringsSep " " [
          # nvidia assume that by default your CPU does not support PAT,
          # but this is effectively never the case in 2023
          "NVreg_UsePageAttributeTable=1"
          # This is sometimes needed for ddc/ci support, see
          # https://www.ddcutil.com/nvidia/
          "NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100"
        ];
    };

    environment.variables = {
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __GL_THREADED_OPTIMIZATION = "1";
      __GL_SHADER_CACHE = "1";
    };
  };
}
