{
  config.substrate.modules.programs.libreoffice = {
    provides = [
      "programs:libreoffice"
      "gui"
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.libreoffice ];
      };
  };
}
