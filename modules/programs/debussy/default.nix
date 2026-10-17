{
  config.substrate.modules.programs.debussy = {
    provides = [
      "programs:debussy"
      "audio:production"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.debussy ];
      };
  };
}
