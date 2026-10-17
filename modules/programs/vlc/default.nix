{
  config.substrate.modules.programs.vlc = {
    provides = [
      "programs:vlc"
      "gui"
    ];
    requires = [ "gui" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.vlc ];
      };
  };
}
