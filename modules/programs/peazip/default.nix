{
  config.substrate.modules.programs.peazip = {
    provides = [
      "programs:peazip"
      "gui"
    ];
    requires = [ "gui" ];
    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.app.archiver = lib.mkDefault {
          package = pkgs.peazip;
          desktopName = "peazip.desktop";
        };

        home.packages = [ pkgs.peazip ];
      };
  };
}
