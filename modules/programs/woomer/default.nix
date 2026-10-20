{
  config.substrate.modules.programs.woomer = {
    tags = [ "desktop" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.woomer ];
      };
  };
}
