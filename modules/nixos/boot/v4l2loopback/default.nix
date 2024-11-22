{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.boot.v4l2loopback;
in
{

  options.hdwlinux.boot.v4l2loopback = {
    enable = lib.mkOption {
      description = "Whether to enable v4l2loopback.";
      type = lib.types.bool;
      default = (builtins.elem "v4l2loopback" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      kernelModules = [ "v4l2loopback" ];
      extraModulePackages = [ config.boot.kernelPackages.v4l2loopback.out ];
      extraModprobeConfig = ''
        options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
      '';
    };
  };
}
