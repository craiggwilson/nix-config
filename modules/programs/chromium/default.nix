{
  config.substrate.modules.programs.chromium = {
    tags = [ "gui" ];

    perUser =
      { pkgs, ... }:
      {
        hdwlinux.programs.browserctl.browsers.chromium = "chromium.desktop";

        packages = [ pkgs.chromium ];
      };
  };
}
