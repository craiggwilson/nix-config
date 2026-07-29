{
  config.substrate.modules.programs.debussy = {
    tags = [ "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.debussy ];
      };
  };
}
