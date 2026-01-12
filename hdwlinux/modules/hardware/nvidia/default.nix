{ config, ... }:
let
  pcicardType = config.substrate.types.pcicard;
in
{
  config.substrate.modules.hardware.nvidia = {
    tags = [ "graphics:nvidia" ];

    generic =
      { lib, ... }:

      {
        options.hdwlinux.hardware.graphics.nvidia.card = lib.mkOption {
          description = "The nvidia graphics card information.";
          type = pcicardType lib;
        };
      };

    nixos =
      { config, lib, ... }:
      let
        convertBusId = busId: "PCI:${builtins.replaceStrings [ "." ] [ ":" ] busId}";
        intelBusId = config.hdwlinux.hardware.graphics.card.busId;
        nvidiaBusId = config.hdwlinux.hardware.graphics.nvidia.card.busId;
        hasBusIds = intelBusId != "" && nvidiaBusId != "";
      in
      {
        services.xserver.videoDrivers = [ "nvidia" ];

        boot.blacklistedKernelModules = [ "nouveau" ];

        hardware.nvidia = {
          modesetting.enable = true;
          nvidiaPersistenced = false;
          nvidiaSettings = true;
          powerManagement.enable = true;
          powerManagement.finegrained = false;
          open = false;
          prime = lib.mkIf hasBusIds {
            sync.enable = true;
            offload.enable = false;
            intelBusId = convertBusId intelBusId;
            nvidiaBusId = convertBusId nvidiaBusId;
          };
        };
      };
  };
}
