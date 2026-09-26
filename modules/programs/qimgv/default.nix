{
  config.substrate.modules.programs.qimgv = {
    tags = [ "gui" ];

    perUser =
      { lib, pkgs, ... }:
      {
        hdwlinux.app.imageViewer = lib.mkDefault {
          package = pkgs.qimgv;
          desktopName = "qimgv.desktop";
        };

        packages = [ pkgs.qimgv ];
      };
  };
}
