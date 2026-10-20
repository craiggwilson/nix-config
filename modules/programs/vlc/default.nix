{
  config.substrate.modules.programs.vlc = {
    tags = [ "desktop" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.vlc ];
      };
  };
}
