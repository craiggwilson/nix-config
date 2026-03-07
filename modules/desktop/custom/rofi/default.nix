{
  config.substrate.modules.desktop.custom.rofi = {
    tags = [ "desktop:custom" ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        colors = config.hdwlinux.theme.colors or { };
        hasColors = colors != { } && builtins.hasAttr "withHashtag" colors;
      in
      {
        programs.rofi = {
          enable = true;
          package = pkgs.rofi;
          cycle = true;
          theme = "theme.rasi";
          extraConfig = {
            "show-icons" = true;
            "display-drun" = "";
            "display-run" = "";
            "display-filebrowser" = "";
            "display-power-menu" = "󰐥";
            "display-hyprland-keybinds" = "⌨";
            "display-window" = "";
            "drun-display-format" = "{name}";
            "window-format" = "{w} · {c} · {t}";
            "modes" = "window,drun";
          };
        };

        xdg.configFile."rofi/colors.rasi".text = lib.mkIf hasColors ''
          * {
              background:     ${colors.withHashtag.base00};
              background-alt: ${colors.withHashtag.base01};
              foreground:     ${colors.withHashtag.base05};
              selected:       ${colors.withHashtag.base07};
              active:         ${colors.withHashtag.base06};
              urgent:         ${colors.withHashtag.base0E};

              base00: ${colors.withHashtag.base00};
              base01: ${colors.withHashtag.base01};
              base02: ${colors.withHashtag.base02};
              base03: ${colors.withHashtag.base03};
              base04: ${colors.withHashtag.base04};
              base05: ${colors.withHashtag.base05};
              base06: ${colors.withHashtag.base06};
              base07: ${colors.withHashtag.base07};
              base08: ${colors.withHashtag.base08};
              base09: ${colors.withHashtag.base09};
              base0A: ${colors.withHashtag.base0A};
              base0B: ${colors.withHashtag.base0B};
              base0C: ${colors.withHashtag.base0C};
              base0D: ${colors.withHashtag.base0D};
              base0E: ${colors.withHashtag.base0E};
              base0F: ${colors.withHashtag.base0F};
          }
        '';

        # Add menu theme files using symlinks for easy editing
        xdg.configFile."rofi/app-menu.rasi".source =
          config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/modules/desktop/custom/rofi/app-menu.rasi";
        xdg.configFile."rofi/networkmenu.rasi".source =
          config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/modules/desktop/custom/rofi/networkmenu.rasi";
        xdg.configFile."rofi/powermenu.rasi".source =
          config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/modules/desktop/custom/rofi/powermenu.rasi";
        xdg.configFile."rofi/screen-capture-menu.rasi".source =
          config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/modules/desktop/custom/rofi/screen-capture-menu.rasi";
        xdg.configFile."rofi/screen-record-menu.rasi".source =
          config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/modules/desktop/custom/rofi/screen-record-menu.rasi";
        xdg.configFile."rofi/theme.rasi".source =
          config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/modules/desktop/custom/rofi/theme.rasi";
      };
  };
}
