{
  config.substrate.modules.programs.vlc = {
    provides = [ "gui" ];
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.vlc ];
      };
  };
}
