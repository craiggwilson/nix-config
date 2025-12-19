{
  config.substrate.modules.programs.peazip = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        hdwlinux.apps.archiver = {
          package = pkgs.peazip;
          desktopName = "peazip.desktop";
        };

        home.packages = [ pkgs.peazip ];
      };
  };
}

