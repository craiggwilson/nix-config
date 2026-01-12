{
  config.substrate.modules.desktop.custom.hyprlock = {
    tags = [ "desktop:custom" ];

    nixos = {
      security.pam.services.hyprlock.text = ''
        auth sufficient pam_unix.so try_first_pass likeauth nullok
        auth sufficient pam_fprintd.so
        auth include login
      '';
    };

    homeManager =
      { config, lib, pkgs, ... }:
      let
        colors = config.hdwlinux.theme.colors or { };
        hasColors = colors != { } && builtins.hasAttr "withHashtag" colors;
        rgb = color: "rgb(${color})";
        wallpaper = config.hdwlinux.theme.wallpaper or null;
      in
      {
        home.packages = [ pkgs.hyprlock ];

        xdg.configFile."hypr/hyprlock.conf".text = lib.mkIf hasColors ''
          general {
            disable_loading_bar = true
            hide_cursor = true
          }

          background {
            monitor =
            path = ${if wallpaper != null then toString wallpaper else ""}
            blur_passes = 0
            color = ${rgb colors.base00}
          }

          # TIME
          label {
            monitor =
            text = cmd[update:30000] echo "$(date +"%R")"
            color = ${rgb colors.base05}
            font_size = 90
            position = -30, 0
            halign = right
            valign = top
          }

          # DATE 
          label {
            monitor = 
            text = cmd[update:43200000] echo "$(date +"%A, %d %B %Y")"
            color = ${rgb colors.base05}
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
            outer_color = ${rgb colors.base0D}
            inner_color = ${rgb colors.base02}
            font_color = ${rgb colors.base05}
            fade_on_empty = false
            placeholder_text = <span foreground="${colors.withHashtag.base05}"><i>󰌾 Logged in as </i></span><span foreground="${colors.withHashtag.base0B}">$USER</span>
            hide_input = false
            check_color = ${rgb colors.base0D}
            fail_color = ${rgb colors.base08}
            fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
            capslock_color = ${rgb colors.base0A}
            position = 0, -35
            halign = center
            valign = center
          }
        '';
      };
  };
}

