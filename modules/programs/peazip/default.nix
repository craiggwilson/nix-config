{
  config.substrate.modules.programs.peazip = {
    provides = [ "gui" ];
    tags = [ "gui" ];

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
