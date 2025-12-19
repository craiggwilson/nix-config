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

        xdg.configFile."rofi/theme.rasi".text = ''
          @import "colors.rasi"

          * {
              font:                        "JetBrainsMono Nerd Font 12";
              border-colour:               var(selected);
              handle-colour:               var(selected);
              background-colour:           var(background);
              foreground-colour:           var(foreground);
              alternate-background:        var(background-alt);
              normal-background:           var(background);
              normal-foreground:           var(foreground);
              urgent-background:           var(urgent);
              urgent-foreground:           var(background);
              active-background:           var(active);
              active-foreground:           var(background);
              selected-normal-background:  var(selected);
              selected-normal-foreground:  var(background);
              selected-urgent-background:  var(active);
              selected-urgent-foreground:  var(background);
              selected-active-background:  var(urgent);
              selected-active-foreground:  var(background);
              alternate-normal-background: var(background);
              alternate-normal-foreground: var(foreground);
              alternate-urgent-background: var(urgent);
              alternate-urgent-foreground: var(background);
              alternate-active-background: var(active);
              alternate-active-foreground: var(background);
          }

          window {
              transparency:                "real";
              location:                    center;
              anchor:                      center;
              fullscreen:                  false;
              width:                       600px;
              x-offset:                    0px;
              y-offset:                    0px;
              enabled:                     true;
              margin:                      0px;
              padding:                     0px;
              border:                      0px solid;
              border-radius:               10px;
              border-color:                @border-colour;
              cursor:                      "default";
              background-color:            @background-colour;
          }

          mainbox {
              enabled:                     true;
              spacing:                     10px;
              margin:                      0px;
              padding:                     30px;
              border:                      0px solid;
              border-radius:               0px 0px 0px 0px;
              border-color:                @border-colour;
              background-color:            transparent;
              children:                    [ "inputbar", "listview" ];
          }

          inputbar {
              enabled:                     true;
              spacing:                     10px;
              margin:                      0px;
              padding:                     15px;
              border:                      0px solid;
              border-radius:               10px;
              border-color:                @border-colour;
              background-color:            @alternate-background;
              text-color:                  @foreground-colour;
              children:                    [ "prompt", "entry" ];
          }

          prompt {
              enabled:                     true;
              background-color:            inherit;
              text-color:                  inherit;
          }

          entry {
              enabled:                     true;
              background-color:            inherit;
              text-color:                  inherit;
              cursor:                      text;
              placeholder:                 "Search...";
              placeholder-color:           inherit;
          }

          listview {
              enabled:                     true;
              columns:                     1;
              lines:                       6;
              cycle:                       true;
              dynamic:                     true;
              scrollbar:                   false;
              layout:                      vertical;
              reverse:                     false;
              fixed-height:                true;
              fixed-columns:               true;
              spacing:                     5px;
              margin:                      0px;
              padding:                     0px;
              border:                      0px solid;
              border-radius:               0px;
              border-color:                @border-colour;
              background-color:            transparent;
              text-color:                  @foreground-colour;
              cursor:                      "default";
          }
        '';

        # Add menu theme files using symlinks for easy editing
        xdg.configFile."rofi/app-menu.rasi".source =
          config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/hdwlinux/modules/desktop/custom/rofi/app-menu.rasi";
        xdg.configFile."rofi/networkmenu.rasi".source =
          config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/hdwlinux/modules/desktop/custom/rofi/networkmenu.rasi";
        xdg.configFile."rofi/powermenu.rasi".source =
          config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/hdwlinux/modules/desktop/custom/rofi/powermenu.rasi";
        xdg.configFile."rofi/screen-capture-menu.rasi".source =
          config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/hdwlinux/modules/desktop/custom/rofi/screen-capture-menu.rasi";
        xdg.configFile."rofi/screen-record-menu.rasi".source =
          config.lib.file.mkOutOfStoreSymlink "${config.hdwlinux.flake}/hdwlinux/modules/desktop/custom/rofi/screen-record-menu.rasi";
      };
  };
}
