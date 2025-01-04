{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.notifier;
in
{
  options.hdwlinux.desktopManagers.hyprland.notifier = {
    enable = lib.hdwlinux.mkEnableOption "notifier" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.libnotify
      (pkgs.hdwlinux.writeSwitchedShellApplication {
        name = "notifyctl";
        runtimeInputs = [
          config.services.mako.package
          pkgs.jq
          pkgs.ripgrep
        ];
        cases = {
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
        defaultTimeout = 5000;
        ignoreTimeout = false;
        borderRadius = 5;
        borderSize = 1;
        extraConfig = ''
          [mode=idle]
          default-timeout=0
          ignore-timeout=1

          [mode=do-not-disturb]
          invisible=1
        '';
      }
      (lib.mkIf config.hdwlinux.theme.enable {
        backgroundColor = config.hdwlinux.theme.colors.withHashtag.base00;
        borderColor = config.hdwlinux.theme.colors.withHashtag.base00;
        progressColor = config.hdwlinux.theme.colors.withHashtag.base02;
        textColor = config.hdwlinux.theme.colors.withHashtag.base05;
        extraConfig = ''
          [urgency=high]
          border-color=${config.hdwlinux.theme.colors.withHashtag.base09}
        '';
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
