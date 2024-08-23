{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hdwlinux.features.hyprlock;
  rgb = color: "rgb(${color})";
in
{
  options.hdwlinux.features.hyprlock = {
    enable = lib.hdwlinux.mkEnableOpt [ "desktop:hyprland" ] config.hdwlinux.features.tags;
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.hyprlock ];

    xdg.configFile."hypr/hyprlock.conf".text = ''
      general {
        disable_loading_bar = true
        hide_cursor = true
      }

      background {
        monitor =
        path = ${builtins.elemAt config.hdwlinux.theme.wallpapers 0}
        blur_passes = 0
        color = ${rgb config.hdwlinux.theme.colors.base00}
      }

      # TIME
      label {
        monitor =
        text = cmd[update:30000] echo "$(date +"%R")"
        color = ${rgb config.hdwlinux.theme.colors.base05}
        font_size = 90
        position = -30, 0
        halign = right
        valign = top
      }

      # DATE 
      label {
        monitor = 
        text = cmd[update:43200000] echo "$(date +"%A, %d %B %Y")"
        color = ${rgb config.hdwlinux.theme.colors.base05}
        font_size = 25
        position = -30, -150
        halign = right
        valign = top
      }

      # INPUT FIELD
      input-field {
        monitor =
        size = 300, 60
        outline_thickness = 4
        dots_size = 0.2
        dots_spacing = 0.2
        dots_center = true
        outer_color = ${rgb config.hdwlinux.theme.colors.base0D}
        inner_color = ${rgb config.hdwlinux.theme.colors.base02}
        font_color = ${rgb config.hdwlinux.theme.colors.base05}
        fade_on_empty = false
        placeholder_text = <span foreground="#${config.hdwlinux.theme.colors.withHashtag.base05}"><i>󰌾 Logged in as </i></span><span foreground="#${config.hdwlinux.theme.colors.withHashtag.base0B}">$USER</span>
        hide_input = false
        check_color = ${rgb config.hdwlinux.theme.colors.base0D}
        fail_color = ${rgb config.hdwlinux.theme.colors.base08}
        fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
        capslock_color = ${rgb config.hdwlinux.theme.colors.base0A}
        position = 0, -35
        halign = center
        valign = center
      }
    '';
  };
}
