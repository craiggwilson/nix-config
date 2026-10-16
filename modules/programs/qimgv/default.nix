{
  config.substrate.modules.programs.qimgv = {
    provides = [ "programs:qimgv" "gui" ];
    tags = [ "gui" ];

    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.app.imageViewer = lib.mkDefault {
          package = pkgs.qimgv;
          desktopName = "qimgv.desktop";
        };

        home.packages = [ pkgs.qimgv ];
      };
  };
}
