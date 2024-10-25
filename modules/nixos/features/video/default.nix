{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.features.video;
in
{
  options.hdwlinux.features.video = {
    enable = lib.hdwlinux.mkEnableOpt [ "video" ] config.hdwlinux.features.tags;
    intelBusId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    nvidiaBusId = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    boot.blacklistedKernelModules = [ "nouveau" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    services.xserver.videoDrivers = [
      "modesetting"
    ];
  };
}
