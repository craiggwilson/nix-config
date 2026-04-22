{
  config.substrate.modules.programs.mato = {
    tags = [ "ai:agent" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.mato ];
      };
  };
}
