{
  config.substrate.modules.programs.vlc = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.vlc ];
      };
  };
}

