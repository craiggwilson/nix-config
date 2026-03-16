{
  config.substrate.modules.programs.chromium = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
        # hdwlinux.apps.webBrowser = {
        #   package = config.programs.chromium.package;
        #   desktopName = "chromium.desktop";
        # };

        hdwlinux.programs.browserctl.browsers.chromium = "chromium.desktop";

        programs.chromium = {
          enable = true;
          package = pkgs.chromium;
          commandLineArgs = [
            "--enable-features=UseOzonePlatform"
            "--ozone-platform=wayland"
          ];
        };
      };
  };
}
