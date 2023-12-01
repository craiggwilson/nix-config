{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.features.kitty;
in
{
  options.hdwlinux.features.kitty = with types; {
    enable = mkEnableOpt ["gui"] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {

    home.shellAliases = {
      "ssh" = "kitty +kitten ssh";
    };

    programs.kitty = {
      enable = true;
      font.name = mkForce "FiraCode Nerd Font Mono";
      extraConfig = ''
        enabled_layouts splits,tall,fat
        map ctrl+c copy_or_interrupt
        map ctrl+v paste_from_clipboard
        map ctrl+equal change_font_size all +2.0
        map ctrl+minus change_font_size all -2.0
        map ctrl+shift+minus launch --location=hsplit
        map ctrl+shift+\ launch --location=vsplit
        map ctrl+shift+left resize_window narrower
        map ctrl+shift+right resize_window wider
        map ctrl+shift+up resize_window taller
        map ctrl+shift+down resize_window shorter 3

        enable_audio_bell no

        tab_bar_edge top
        tab_bar_min_tabs 2
        tab_bar_margin_height 0.0 8.0
        tab_bar_style powerline
        tab_powerline_style slanted
        tab_activity_symbol ◉

        background ${config.lib.stylix.colors.withHashtag.base00}
        foreground ${config.lib.stylix.colors.withHashtag.base05}
        selection_background ${config.lib.stylix.colors.withHashtag.base07}
        selection_foreground ${config.lib.stylix.colors.withHashtag.base00}
        url_color ${config.lib.stylix.colors.withHashtag.base0C}
        cursor ${config.lib.stylix.colors.withHashtag.base07}
        active_border_color ${config.lib.stylix.colors.withHashtag.base08}
        inactive_border_color ${config.lib.stylix.colors.withHashtag.base0A}
        active_tab_background ${config.lib.stylix.colors.withHashtag.base00}
        active_tab_foreground ${config.lib.stylix.colors.withHashtag.base09}
        inactive_tab_background ${config.lib.stylix.colors.withHashtag.base02}
        inactive_tab_foreground ${config.lib.stylix.colors.withHashtag.base05}
        tab_bar_background ${config.lib.stylix.colors.withHashtag.base02}

        # normal
        color0 ${config.lib.stylix.colors.withHashtag.base00}
        color1 ${config.lib.stylix.colors.withHashtag.base08}
        color2 ${config.lib.stylix.colors.withHashtag.base0B}
        color3 ${config.lib.stylix.colors.withHashtag.base0A}
        color4 ${config.lib.stylix.colors.withHashtag.base0D}
        color5 ${config.lib.stylix.colors.withHashtag.base0E}
        color6 ${config.lib.stylix.colors.withHashtag.base0C}
        color7 ${config.lib.stylix.colors.withHashtag.base05}

        # bright
        color8  ${config.lib.stylix.colors.withHashtag.base03}
        color9  ${config.lib.stylix.colors.withHashtag.base09}
        color10 ${config.lib.stylix.colors.withHashtag.base01}
        color11 ${config.lib.stylix.colors.withHashtag.base02}
        color12 ${config.lib.stylix.colors.withHashtag.base04}
        color13 ${config.lib.stylix.colors.withHashtag.base06}
        color14 ${config.lib.stylix.colors.withHashtag.base0F}
        color15 ${config.lib.stylix.colors.withHashtag.base07}
      '';
    };
  };
}
