{
  config.substrate.modules.programs.narratrix = {
    tags = [ "desktop" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.hdwlinux.narratrix ];
      };
  };
}
