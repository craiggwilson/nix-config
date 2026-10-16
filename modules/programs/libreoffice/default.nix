{
  config.substrate.modules.programs.libreoffice = {
    provides = [ "gui" ];
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.libreoffice ];
      };
  };
}
