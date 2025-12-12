{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.hardware.graphics.nvidia;
  convertBusId = busId: "PCI:${builtins.replaceStrings [ "." ] [ ":" ] busId}";
in
{
  options.hdwlinux.hardware.graphics.nvidia = {
    enable = config.lib.hdwlinux.mkEnableOption "nvidia" "graphics:nvidia";
    card = lib.mkOption {
      description = "The nvidia graphics card information.";
      type = lib.hdwlinux.types.pcicard;
    };
  };

  config = lib.mkIf cfg.enable {

    services.xserver.videoDrivers = [
      "nvidia"
    ];

    boot.blacklistedKernelModules = [ "nouveau" ];

    hardware = {
      nvidia = {
        modesetting.enable = true;
        nvidiaPersistenced = false;
        nvidiaSettings = true;
        powerManagement.enable = true;
        powerManagement.finegrained = false;
        open = false;
        prime = {
          sync.enable = true;
          offload.enable = false;
          intelBusId = convertBusId config.hdwlinux.hardware.graphics.card.busId;
          nvidiaBusId = convertBusId cfg.card.busId;
        };
      };
    };

    home-manager.sharedModules = lib.mkIf config.hdwlinux.home-manager.enable [
      {
        hdwlinux.hardware.graphics.nvidia.card = cfg.card;
      }
    ];
  };
}
