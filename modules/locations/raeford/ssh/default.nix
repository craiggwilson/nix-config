{
  config.substrate.modules.locations.raeford.ssh = {
    tags = [ "users:craig" "raeford" ];
    homeManager = { config, ... }:
    let
      domain = config.hdwlinux.networking.domain;
    in
    {
      hdwlinux.security.ssh.settings."*.${domain} *.tailc675f.ts.net" = {
        ForwardX11 = true;
      };
    };
  };
}

