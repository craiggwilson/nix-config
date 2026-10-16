{
  config.substrate.modules.programs.papers = {
    provides = [ "gui" ];
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
