{
  config.substrate.modules.locations.raeford.ssh = {
    tags = [ "users:craig" "raeford" ];
    homeManager = { config, ... }:
    let
      domain = config.hdwlinux.networking.domain;
    in
    {
      hdwlinux.security.ssh.matchBlocks.raeford-hosts = {
        host = "*.${domain} *.tailc675f.ts.net";
        forwardX11 = true;
      };
    };
  };
}

