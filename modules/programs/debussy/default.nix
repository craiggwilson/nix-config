{
  config.substrate.modules.programs.debussy = {
    tags = [ "profile:personal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.debussy ];
      };
  };
}
