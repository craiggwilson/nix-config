# Theme options leaf. Palettes live in the substrate theming extension's
# registry (substrate.settings.theming.palettes); selection is
# `theming.active`, set per host (NixOS surfaces) and per user (Home
# Manager surfaces). hdwlinux.theme.* is kept as a derived convenience view
# over the active palette so existing consumers read one option; wallpaper
# has no palette representation and stays a plain option.
{
  config.substrate.modules.theming.options = {
    nixos =
      {
        lib,
        config,
        theme,
        ...
      }:
      {
        options.hdwlinux.theme = {
          colors = lib.mkOption {
            description = "The current theme colors with hex, rgb, and ansi mode sub-attrsets.";
            type = lib.types.attrs;
            default = { };
          };
        };

        config = lib.mkMerge [
          (lib.mkIf (config.theming.active != null) {
            hdwlinux.theme.colors = theme.palettes.${config.theming.active}.colors;
          })
          # TTY/console palette follows the derived colors.
          (lib.mkIf (config.hdwlinux.theme.colors != { }) {
            console.colors =
              let
                s = config.hdwlinux.theme.colors.ansi;
              in
              [
                s.black.hex
                s.red.hex
                s.green.hex
                s.yellow.hex
                s.blue.hex
                s.magenta.hex
                s.cyan.hex
                s.white.hex
                s.brightBlack.hex
                s.brightRed.hex
                s.brightGreen.hex
                s.brightYellow.hex
                s.brightBlue.hex
                s.brightMagenta.hex
                s.brightCyan.hex
                s.brightWhite.hex
              ];
          })
        ];
      };

    homeManager =
      {
        lib,
        config,
        pkgs,
        theme,
        ...
      }:
      {
        options.hdwlinux.theme = {
          colors = lib.mkOption {
            description = "The current theme colors with hex, rgb, and ansi mode sub-attrsets.";
            type = lib.types.attrs;
            default = { };
          };
          cursor = lib.mkOption {
            description = "The cursor theme.";
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  package = lib.mkOption {
                    type = lib.types.package;
                    description = "Package providing the cursor theme.";
                  };
                  name = lib.mkOption {
                    type = lib.types.str;
                    description = "The cursor name within the package.";
                  };
                  size = lib.mkOption {
                    type = lib.types.int;
                    default = 32;
                    description = "The cursor size.";
                  };
                };
              }
            );
            default = null;
          };
          dark = lib.mkOption {
            description = "Whether the theme is dark.";
            type = lib.types.bool;
            default = true;
          };
          wallpaper = lib.mkOption {
            description = "The wallpaper for the system.";
            type = lib.types.nullOr lib.types.path;
            default = null;
          };
        };

        config = lib.mkMerge [
          (lib.mkIf (config.theming.active != null) {
            hdwlinux.theme =
              let
                palette = theme.palettes.${config.theming.active};
              in
              {
                colors = palette.colors;
                dark = palette.dark;
                cursor =
                  if palette.cursor == null then
                    null
                  else
                    {
                      inherit (palette.cursor) name size;
                      package = palette.cursor.package pkgs;
                    };
              };
          })
          (lib.mkIf (config.hdwlinux.theme.cursor != null) {
            home.pointerCursor = {
              enable = true;
              package = config.hdwlinux.theme.cursor.package;
              name = config.hdwlinux.theme.cursor.name;
              gtk.enable = true;
              hyprcursor = {
                enable = true;
                size = config.hdwlinux.theme.cursor.size;
              };
              x11.enable = true;
            };

            gtk = {
              enable = true;
              gtk3.extraConfig = {
                gtk-application-prefer-dark-theme = config.hdwlinux.theme.dark;
              };
              gtk4.extraConfig = {
                gtk-application-prefer-dark-theme = config.hdwlinux.theme.dark;
              };
            };
          })
        ];
      };
  };
}
