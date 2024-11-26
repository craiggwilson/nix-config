{
  lib,
  config,
  ...
}:
let
  cfg = config.hdwlinux.theme;
in
{
  options.hdwlinux.theme = {
    enable = config.lib.hdwlinux.mkEnableOption "theming" "theming";
    name = lib.mkOption {
      description = "The name of the theme.";
      type = lib.types.str;
    };
    colors = lib.mkOption {
      description = "The current colors.";
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
    };
    dark = lib.mkOption {
      description = "Whether the theme is dark.";
      type = lib.types.bool;
    };
    wallpapers = lib.mkOption {
      description = "The wallpapers for the system.";
      type = lib.types.listOf lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    home.pointerCursor = {
      package = cfg.cursor.package;
      name = cfg.cursor.name;
      gtk.enable = true;
      hyprcursor = {
        enable = true;
        size = cfg.cursor.size;
      };
      x11.enable = true;
    };

    gtk = {
      enable = true;

      gtk3 = lib.mkIf config.hdwlinux.theme.enable {
        extraConfig = {
          gtk-application-prefer-dark-theme = config.hdwlinux.theme.dark;
        };
        extraCss = lib.mkIf (config.gtk.theme == null) config.hdwlinux.theme.colors.adwaitaGtkCss;
      };
      gtk4 = lib.mkIf config.hdwlinux.theme.enable {
        extraConfig = {
          gtk-application-prefer-dark-theme = config.hdwlinux.theme.dark;
        };
        extraCss = lib.mkIf (config.gtk.theme == null) config.hdwlinux.theme.colors.adwaitaGtkCss;
      };
    };
  };
}
