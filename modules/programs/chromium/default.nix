{
  config.substrate.modules.programs.chromium = {
    tags = [ "desktop" ];

    homeManager =
      { pkgs, ... }:
      {
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
