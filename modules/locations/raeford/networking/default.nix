{
  config.substrate.modules.locations.raeford.networking = {
    tags = [ "location:raeford" ];

    generic = {
      hdwlinux.networking.domain = "raeford.wilsonfamilyhq.com";
      hdwlinux.networking.lanCidrs = [ "192.168.10.0/24" ];
    };
  };
}
