{
  config.substrate.modules.programs.debussy = {
    provides = [
      "programs:debussy"
      "audio:composition"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.debussy ];
      };
  };
}
