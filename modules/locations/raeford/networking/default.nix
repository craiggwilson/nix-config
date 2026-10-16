{
  config.substrate.modules.locations.raeford.networking = {
    provides = [ "locations:raeford:networking" "hardware:networking" ];
    requires = [ "location:raeford" ];
    tags = [ "raeford" ];

    generic = {
      hdwlinux.networking.domain = "raeford.wilsonfamilyhq.com";
      hdwlinux.networking.lanCidrs = [ "192.168.10.0/24" ];
    };
  };
}
