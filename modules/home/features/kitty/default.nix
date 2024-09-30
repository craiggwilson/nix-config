{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.hdwlinux;
let
  cfg = config.hdwlinux.features.kitty;
in
{
  options.hdwlinux.features.kitty = with types; {
    enable = mkEnableOpt [ "gui" ] config.hdwlinux.features.tags;
  };

  config = mkIf cfg.enable {

    programs.kitty = {
      enable = true;
      font.name = mkForce "FiraCode Nerd Font Mono";
      settings =
        with config.hdwlinux.theme.colors.withHashtag;
        mkIf config.hdwlinux.theme.enable {
          color0 = base00;
          color1 = base08;
          color2 = base0B;
          color3 = base0A;
          color4 = base0D;
          color5 = base0E;
          color6 = base0C;
          color7 = base05;
          color8 = base03;
          color9 = base08;
          color10 = base0B;
          color11 = base0A;
          color12 = base0D;
          color13 = base0E;
          color14 = base0C;
          color15 = base07;
          color16 = base09;
          color17 = base0F;
          color18 = base01;
          color19 = base02;
          color20 = base04;
          color21 = base06;
        };

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
      '';
    };
  };
}
