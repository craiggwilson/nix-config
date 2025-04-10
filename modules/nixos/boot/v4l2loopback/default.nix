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
    enable = config.lib.hdwlinux.mkEnableOption "v4l2loopback" "v4l2loopback";
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
