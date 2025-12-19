{
  config.substrate.modules.desktop.custom.notifier = {
    tags = [ "desktop:custom" ];

    homeManager =
      { config, lib, pkgs, ... }:
      let
        colors = config.hdwlinux.theme.colors or { };
        hasColors = colors != { } && builtins.hasAttr "withHashtag" colors;
      in
      {
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
              watch = builtins.readFile ./notifyctl-watch.sh;
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
          (lib.mkIf hasColors {
            settings = {
              background-color = colors.withHashtag.base00;
              border-color = colors.withHashtag.base00;
              progress-color = colors.withHashtag.base02;
              text-color = colors.withHashtag.base05;

              "urgency=high" = {
                border-color = colors.withHashtag.base09;
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
  };
}

