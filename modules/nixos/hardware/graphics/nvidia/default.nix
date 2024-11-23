{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.hardware.graphics.nvidia;
  convertBusId = busId: "PCI:${builtins.replaceStrings [ "." ] [ ":" ] busId}";
in
{
  options.hdwlinux.hardware.graphics.nvidia = {
    enable = lib.mkOption {
      description = "Whether to enable bluetooth.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "video:nvidia" config.hdwlinux.features.tags);
    };
    card = lib.mkOption {
      description = "The nvidia graphics card information.";
      type = lib.hdwlinux.pcicard;
    };
  };

  config = lib.mkIf cfg.enable {
    hdwlinux.hardware.graphics.enable = lib.mkDefault true;

    services.xserver.videoDrivers = [
      "nvidia"
    ];

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
          intelBusId = convertBusId config.hdwlinux.hardware.graphics.card.busId;
          nvidiaBusId = convertBusId cfg.card.busId;
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

    home-manager.sharedModules = lib.mkIf config.hdwlinux.home-manager.enable [
      {
        hdwlinux.video.nvidia = cfg.card;
      }
    ];
  };
}
