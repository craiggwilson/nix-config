{
  config.substrate.modules.locations.raeford.scanners = {
    provides = [ "hardware:scanning" ];
    requires = [ "location:raeford" ];
    tags = [
      "raeford"
      "scanning"
    ];

    nixos = {
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
  };
}
