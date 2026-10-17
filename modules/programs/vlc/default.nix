{
  config.substrate.modules.programs.vlc = {
    provides = [
      "programs:vlc"
      "gui"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.vlc ];
      };
  };
}
