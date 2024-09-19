{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.scanning;
in
{
  options.hdwlinux.features.scanning = {
    enable = lib.hdwlinux.mkEnableOpt [ "scanning" ] config.hdwlinux.features.tags;
    raeford = lib.hdwlinux.mkBoolOpt false "Wheter or not to enable Raeford scanning.";
  };

  config = lib.mkIf cfg.enable {

    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
      brscan4 = lib.mkIf cfg.raeford {
        enable = true;
        netDevices = {
          raeford = {
            model = "Brother_HL-L2380DW";
            ip = "192.168.150.71";
          };
        };
      };
    };

    services.avahi = {
      enable = true;
      nssmdns4 = true;
    };
  };
}
