{ lib, ... }:
let
  cursorType = lib.types.submodule {
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
  };
in
{
  # Register the cursor type in substrate.types
  config.substrate.types.cursor = cursorType;

  config.substrate.modules.theming.options = {
    tags = [ ]; # Always included
    homeManager =
      { config, lib, ... }:
      {
        options.hdwlinux.theme = {
          name = lib.mkOption {
            description = "The name of the theme.";
            type = lib.types.str;
            default = "";
          };
          colors = lib.mkOption {
            description = "The current colors.";
            type = lib.types.attrs;
            default = { };
          };
          cursor = lib.mkOption {
            description = "The cursor theme.";
            type = lib.types.nullOr cursorType;
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
