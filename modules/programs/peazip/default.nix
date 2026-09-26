{
  config.substrate.modules.programs.peazip = {
    tags = [ "gui" ];

    perUser =
      { lib, pkgs, ... }:
      {
        hdwlinux.app.archiver = lib.mkDefault {
          package = pkgs.peazip;
          desktopName = "peazip.desktop";
        };

        packages = [ pkgs.peazip ];
      };
  };
}
