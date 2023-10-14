{ options, config, lib, pkgs, ... }:
with lib;
with lib.hdwlinux;
let 
  cfg = config.hdwlinux.packages.kitty;
in
{
  options.hdwlinux.packages.kitty = with types; {
    enable = mkBoolOpt false "Whether or not to enable kitty.";
    extraConfig = mkStrOpt "" (mdDoc "Option passed to home-manager's `programs.kitty.extraConfig`.");
  };

  config.hdwlinux.home = mkIf cfg.enable {
    programs.kitty =  {
      enable = true;
      extraConfig = cfg.extraConfig + ''
        map ctrl+c copy_or_interrupt
        map ctrl+v paste_from_clipboard

        background_opacity 0.6
        enable_audio_bell no
        tab_bar_style powerline
        tab_bar_edge = top

        selection_foreground  #000000
        selection_background  #${config.hdwlinux.theme.color5}
        url_color             #${config.hdwlinux.theme.color2}
        cursor                #${config.hdwlinux.theme.color9}

        # black
        color0   #${config.hdwlinux.theme.color1}
        color8   #${config.hdwlinux.theme.color1}

        # red
        color1   #${config.hdwlinux.theme.color11}
        color9   #${config.hdwlinux.theme.color11}

        # green
        color2   #${config.hdwlinux.theme.color14}
        color10  #${config.hdwlinux.theme.color14}

        # yellow
        color3   #${config.hdwlinux.theme.color13}
        color11  #${config.hdwlinux.theme.color13}

        # blue
        color4  #${config.hdwlinux.theme.color9}
        color12 #${config.hdwlinux.theme.color9}

        # magenta
        color5   #${config.hdwlinux.theme.color15}
        color13  #${config.hdwlinux.theme.color15}

        # cyan
        color6   #${config.hdwlinux.theme.color8}
        color14  #${config.hdwlinux.theme.color8}

        # white
        color7   #${config.hdwlinux.theme.color6}
        color15  #${config.hdwlinux.theme.color6}
      '';
    };
  };
}
