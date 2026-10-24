{
  config.substrate.modules.services.playerctld = {
    tags = [
      "desktop"
      "capability:audio"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.playerctl ];
        services.playerctld.enable = true;
      };
  };
}
