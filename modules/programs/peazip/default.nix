{
  config.substrate.modules.programs.peazip = {
    tags = [ "gui" ];

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
