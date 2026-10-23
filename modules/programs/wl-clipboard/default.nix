{
  config.substrate.modules.programs.wl-clipboard = {
    tags = [ "desktop" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.wl-clipboard ];
      };
  };
}
