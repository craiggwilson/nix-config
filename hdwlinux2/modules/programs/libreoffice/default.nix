{
  config.substrate.modules.programs.libreoffice = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.libreoffice ];
      };
  };
}

