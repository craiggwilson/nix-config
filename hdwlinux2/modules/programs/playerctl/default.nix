{
  config.substrate.modules.programs.playerctl = {
    tags = [ "gui" "audio" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.playerctl ];
      };
  };
}

