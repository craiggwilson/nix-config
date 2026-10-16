{
  config.substrate.modules.programs.libreoffice = {
    provides = [ "programs:libreoffice" "gui" ];
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.libreoffice ];
      };
  };
}
