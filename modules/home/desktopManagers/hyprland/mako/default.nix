{
  config,
  lib,
  ...
}:

let
  cfg = config.hdwlinux.desktopManagers.hyprland.mako;
in
{
  options.hdwlinux.desktopManagers.hyprland.mako = {
    enable = lib.hdwlinux.mkEnableOption "mako" config.hdwlinux.desktopManagers.hyprland.enable;
  };

  config = lib.mkIf cfg.enable {
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
        on-timeout = "${config.services.mako.package}/bin/makoctl mode -a idle";
        on-resume = "${config.services.mako.package}/bin/makoctl mode -r idle";
      }
    ];
  };
}
