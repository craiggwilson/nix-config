{ config, ... }:
let
  graphicsCardType = config.substrate.types.graphicsCard;
in
{
  config.substrate.modules.hardware.graphics.nvidia = {
    tags = [ "graphics:nvidia" ];

    generic =
      { lib, ... }:

      {
        options.hdwlinux.hardware.graphics.nvidia.card = lib.mkOption {
          description = "The nvidia graphics card information.";
          type = graphicsCardType lib;
        };
      };

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
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
          powerManagement.finegrained = true;
          open = false;
          prime = lib.mkIf hasBusIds {
            sync.enable = false;
            offload.enable = true;
            intelBusId = convertBusId intelBusId;
            nvidiaBusId = convertBusId nvidiaBusId;
          };
        };
      };
  };
}
