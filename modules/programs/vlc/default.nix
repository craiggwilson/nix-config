{
  config.substrate.modules.programs.vlc = {
    provides = [ "programs:vlc" "gui" ];
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.vlc ];
      };
  };
}
