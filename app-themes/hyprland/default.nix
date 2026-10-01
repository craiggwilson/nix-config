{
  # Hyprland colors as a runtime template (theming adapter). The colors live
  # in a sourced fragment, so `hyprctl reload` repaints borders, shadows and
  # the desktop background without a rebuild.
  config.substrate.settings.theming.apps.hyprland.enabled =
    { config, ... }:
    config.wayland ? windowManager
    && config.wayland.windowManager ? hyprland
    && config.wayland.windowManager.hyprland.enable;

  config.substrate.settings.theming.apps.hyprland = {
    templates =
      { theme, ... }:
      let
        colors = theme.colors.hex;
        rgb = color: "rgb(${color})";
        rgba = color: alpha: "rgba(${color}${alpha})";
      in
      {
        "hypr/hdwlinux-theme.conf" = {
          content = ''
            misc {
              background_color = ${rgb colors.base00}
            }

            general {
              col.active_border = ${rgb colors.base0E}
              col.inactive_border = ${rgb colors.base03}
            }

            decoration {
              shadow {
                color = ${rgba colors.base00 "99"}
              }
            }

            group {
              col.border_inactive = ${rgb colors.base0D}
              col.border_active = ${rgb colors.base06}
              col.border_locked_active = ${rgb colors.base06}
            }
          '';
          dest = "$HOME/.config/hypr/hdwlinux-theme.conf";
        };
      };

    onSwitch =
      { ... }:
      ''
        hyprctl reload || true
      '';
  };
}
