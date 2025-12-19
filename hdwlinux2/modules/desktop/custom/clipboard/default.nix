{
  config.substrate.modules.desktop.custom.clipboard = {
    tags = [ "desktop:custom" ];

    homeManager =
      { config, lib, pkgs, ... }:
      {
        home.packages = [
          pkgs.wl-clipboard
          (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
            name = "clipboardctl";
            runtimeInputs = [
              config.programs.rofi.package
              config.services.cliphist.package
              pkgs.wl-clipboard
            ];
            subcommands = {
              copy = "wl-copy";
              list = "cliphist list";
              paste = "wl-paste";
              show-menu = "cliphist list | rofi -dmenu | cliphist decode | wl-copy";
            };
          })
        ];

        systemd.user.services.cliphist.Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
        systemd.user.services.cliphist-images.Unit.ConditionEnvironment = lib.mkDefault "WAYLAND_DISPLAY";

        services.cliphist.enable = true;
      };
  };
}

