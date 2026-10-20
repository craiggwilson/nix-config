{
  config.substrate.modules.services.playerctld = {
    tags = [
      "desktop"
      "audio"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.playerctl ];
        services.playerctld.enable = true;
      };
  };
}
