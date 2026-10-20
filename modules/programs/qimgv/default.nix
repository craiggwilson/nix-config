{
  config.substrate.modules.programs.qimgv = {
    tags = [ "desktop" ];

    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.desktop.apps.imageViewer = lib.mkDefault {
          package = pkgs.qimgv;
          desktopName = "qimgv.desktop";
        };

        home.packages = [ pkgs.qimgv ];
      };
  };
}
