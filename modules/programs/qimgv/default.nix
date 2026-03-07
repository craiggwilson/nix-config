{
  config.substrate.modules.programs.qimgv = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        hdwlinux.apps.imageViewer = {
          package = pkgs.qimgv;
          desktopName = "qimgv.desktop";
        };

        home.packages = [ pkgs.qimgv ];
      };
  };
}

