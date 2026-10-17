{
  config.substrate.modules.programs.libreoffice = {
    provides = [
      "programs:libreoffice"
      "gui"
    ];
    requires = [ "gui" ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.libreoffice ];
      };
  };
}
