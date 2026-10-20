{
  config.substrate.modules.programs.discord = {
    tags = [ "desktop" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.discord ];
      };
  };
}
