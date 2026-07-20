{
  config.substrate.modules.programs.papers = {
    tags = [ "gui" ];

    homeManager =
      { lib, pkgs, ... }:
      {
        hdwlinux.app.documentViewer = lib.mkDefault {
          package = pkgs.papers;
          desktopName = "org.gnome.Papers.desktop";
        };

        home.packages = [ pkgs.papers ];
      };
  };
}

