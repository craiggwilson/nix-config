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
    enable = config.lib.hdwlinux.mkEnableOption "sane" "scanning";
  };

  config = lib.mkIf cfg.enable {
    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
      brscan4 = lib.mkIf (lib.hdwlinux.matchTag "raeford" config.hdwlinux.tags) {
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
