{
  config.substrate.modules.programs.debussy = {
    provides = [ "programs:debussy" "audio:production" ];
    tags = [ "users:craig:personal" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.debussy ];
      };
  };
}
