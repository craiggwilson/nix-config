{
  config.substrate.modules.programs.debussy = {
    provides = [ "audio:composition" ];
    tags = [ "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.debussy ];
      };
  };
}
