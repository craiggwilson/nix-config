{ lib, pkgs, config, ... }:
{
  hdwlinux.packages.kitty = {
    extraConfig = ''
      include ${./themes/Nord.conf};

      background_opacity 0.6
      enable_audio_bell no
      tab_bar_style powerline
      tab_bar_edge = top

      map ctrl+c copy_or_interrupt
      map ctrl+v paste_from_clipboard
    '';
  };
}
