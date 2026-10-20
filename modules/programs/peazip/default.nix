{
  config.substrate.modules.programs.peazip = {
    tags = [ "desktop" ];

    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.desktop.apps.archiver = lib.mkDefault {
          package = pkgs.peazip;
          desktopName = "peazip.desktop";
        };

        home.packages = [ pkgs.peazip ];
      };
  };
}
