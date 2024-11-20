{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.features.video.nvidia;
  convertBusId = busId: "PCI:${builtins.replaceStrings [ "." ] [ ":" ] busId}";
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

    boot = {
      blacklistedKernelModules = [ "nouveau" ];
      kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
    };

    hardware = {
      nvidia = {
        modesetting.enable = true;
        nvidiaPersistenced = true;
        nvidiaSettings = true;
        powerManagement.enable = true;
        powerManagement.finegrained = false;
        open = false;
        prime = {
          sync.enable = true;
          offload.enable = false;
          intelBusId = convertBusId config.hdwlinux.video.intel.busId;
          nvidiaBusId = convertBusId config.hdwlinux.video.nvidia.busId;
        };
      };
    };

    specialisation = {
      on-the-go.configuration = {
        system.nixos.tags = [ "on-the-go" ];
        hardware.nvidia.prime = {
          offload = {
            enable = lib.mkForce true;
            enableOffloadCmd = true;
          };
          sync.enable = lib.mkForce false;
        };
      };
    };
  };
}
