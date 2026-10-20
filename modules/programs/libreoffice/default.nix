{
  config.substrate.modules.programs.libreoffice = {
    tags = [ "desktop" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.libreoffice ];
      };
  };
}
