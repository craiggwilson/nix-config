{
  config.substrate.modules.programs.chromium = {
    tags = [ "gui" ];

    homeManager =
      { pkgs, ... }:
      {
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

