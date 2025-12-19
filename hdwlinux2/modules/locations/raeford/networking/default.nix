let
  domain = "raeford.wilsonfamilyhq.com";
in
{
  config.substrate.modules.locations.raeford.networking = {
    tags = [ "raeford" ];

    nixos = {
      hdwlinux.networking.domain = domain;
    };

    homeManager = {
      hdwlinux.networking.domain = domain;
    };
  };
}
