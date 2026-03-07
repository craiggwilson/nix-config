{
  config.substrate.modules.services.playerctld = {
    tags = [ "gui" "audio" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.playerctl ];
        services.playerctld.enable = true;
      };
  };
}

