{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopEnvironments.wayland.clipboard;
in
{
  options.hdwlinux.desktopEnvironments.wayland.clipboard = {
    enable = lib.hdwlinux.mkEnableOption "clipboard" config.hdwlinux.desktopEnvironments.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
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
    systemd.user.services.cliphist-images.Unit.ConditionEnvironment = "WAYLAND_DISPLAY";

    services.cliphist = {
      enable = true;
    };
  };
}
