{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.wayland.notifier;
in
{
  options.hdwlinux.desktopManagers.wayland.notifier = {
    enable = lib.hdwlinux.mkEnableOption "notifier" config.hdwlinux.desktopManagers.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.libnotify
      (pkgs.hdwlinux.writeShellApplicationWithSubcommands {
        name = "notifyctl";
        runtimeInputs = [
          config.services.mako.package
          pkgs.jq
          pkgs.ripgrep
        ];
        subcommands = {
          add-tag = "makoctl mode -a \"$1\"";
          dismiss-all = "makoctl dismiss --all";
          remove-tag = "makoctl mode -r \"$1\"";
          toggle-tag = "makoctl mode -t \"$1\"";
          watch = ./notifyctl-watch.sh;
        };
      })
    ];

    services.mako = lib.mkMerge [
      {
        enable = true;
        settings = {
          border-radius = 5;
          border-size = 1;
          default-timeout = 5000;
          ignore-timeout = false;

          "mode=idle" = {
            default-timeout = 0;
            ignore-timeout = 1;
          };
          "mode=do-not-disturb" = {
            invisible = 1;
          };
        };
      }
      (lib.mkIf config.hdwlinux.theme.enable {
        settings = {
          background-color = config.hdwlinux.theme.colors.withHashtag.base00;
          border-color = config.hdwlinux.theme.colors.withHashtag.base00;
          progress-color = config.hdwlinux.theme.colors.withHashtag.base02;
          text-color = config.hdwlinux.theme.colors.withHashtag.base05;

          "urgency=high" = {
            border-color = config.hdwlinux.theme.colors.withHashtag.base09;
          };
        };
      })
    ];

    services.hypridle.settings.listener = [
      {
        timeout = 60;
        on-timeout = "notifyctl add-tag idle";
        on-resume = "notifyctl remove-tag idle";
      }
    ];
  };
}
