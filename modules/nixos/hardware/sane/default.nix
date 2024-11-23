{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.hardware.sane;
in
{
  options.hdwlinux.hardware.sane = {
    enable = lib.mkOption {
      description = "Whether to enable sane.";
      type = lib.types.bool;
      default = (lib.hdwlinux.elemPrefix "scanning" config.hdwlinux.features.tags);
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
      brscan4 = lib.mkIf (builtins.elem "raeford" config.hdwlinux.features.tags) {
        enable = true;
        netDevices = {
          raeford = {
            model = "Brother_HL-L2380DW";
            ip = "192.168.150.71";
          };
        };
      };
    };
  };
}
