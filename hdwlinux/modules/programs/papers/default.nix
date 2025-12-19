{
  config.substrate.modules.programs.papers = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        hdwlinux.apps.documentViewer = {
          package = pkgs.papers;
          desktopName = "org.gnome.Papers.desktop";
        };

        home.packages = [ pkgs.papers ];
      };
  };
}

