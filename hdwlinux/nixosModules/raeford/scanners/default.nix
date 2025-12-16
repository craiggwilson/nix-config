{
  config,
  lib,
  ...
}:
let
  cfg = config.hdwlinux.raeford.scanners;
in
{
  options.hdwlinux.raeford.scanners = {
    enable = config.lib.hdwlinux.mkEnableOption "raeford office scanners" "raeford";
  };

  config = lib.mkIf cfg.enable {
    # Enable scanning for raeford office
    hdwlinux.hardware.sane.enable = lib.mkDefault true;

    # Configure the Brother scanner in the raeford office
    hardware.sane.brscan4 = {
      enable = true;
      netDevices = {
        raeford = {
          model = "Brother_HL-L2380DW";
          ip = "192.168.150.71";
        };
      };
    };
  };
}
