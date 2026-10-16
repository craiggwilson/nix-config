{
  config.substrate.modules.programs.chromium = {
    provides = [ "programs:chromium" "gui" ];
    tags = [ "gui" ];

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
