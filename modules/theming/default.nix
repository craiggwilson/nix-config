{
  config.substrate.modules.theming.options = {
    nixos =
      { lib, config, ... }:
      {
        options.hdwlinux.theme = {
          colors = lib.mkOption {
            description = "The current theme colors, including ansi sub-attrset.";
            type = lib.types.attrs;
            default = { };
          };
          system = lib.mkOption {
            description = "The name of the theme that applies to NixOS-level settings (e.g., Plymouth, TTY colors).";
            type = lib.types.str;
          };
        };

        config = lib.mkIf (config.hdwlinux.theme.colors != { }) {
          console.colors =
            let
              c = config.hdwlinux.theme.colors.ansi;
            in
            [
              c.black
              c.red
              c.green
              c.yellow
              c.blue
              c.magenta
              c.cyan
              c.white
              c.brightBlack
              c.brightRed
              c.brightGreen
              c.brightYellow
              c.brightBlue
              c.brightMagenta
              c.brightCyan
              c.brightWhite
            ];
        };
      };

    homeManager =
      { config, lib, ... }:
      {
        options.hdwlinux.theme = {
          colors = lib.mkOption {
            description = "The current theme colors, including ansi and withHashtag sub-attrsets.";
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
          name = lib.mkOption {
            description = "The name of the theme.";
            type = lib.types.str;
            default = "";
          };
          wallpaper = lib.mkOption {
            description = "The wallpaper for the system.";
            type = lib.types.nullOr lib.types.path;
            default = null;
          };
        };

        config = lib.mkIf (config.hdwlinux.theme.cursor != null) {
          home.pointerCursor = {
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
        };
      };
  };
}
