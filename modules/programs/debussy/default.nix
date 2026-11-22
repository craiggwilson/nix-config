{
  config.substrate.modules.programs.debussy = {
    tags = [ "profile:music-notation" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.debussy ];
      };
  };
}
