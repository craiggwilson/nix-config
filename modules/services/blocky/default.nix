{
  config.substrate.modules.services.blocky = {
    tags = [ "host:adblocker" ];

    nixos = {
      services.blocky = {
        enable = true;
        settings = {
          ports.dns = [
            53
            "127.0.0.1:53"
          ];

          upstreams.groups.default = [
            "https://1.1.1.1/dns-query"
            "https://1.0.0.1/dns-query"
          ];

          bootstrapDns = {
            upstream = "https://1.1.1.1/dns-query";
            ips = [
              "1.1.1.1"
              "1.0.0.1"
            ];
          };

          blocking = {
            denylists.ads = [
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            ];

            clientGroupsBlock.default = [ "ads" ];
          };

          caching = {
            minTime = "5m";
            maxTime = "12h";
            prefetching = true;
          };
        };
      };
    };
  };
}
